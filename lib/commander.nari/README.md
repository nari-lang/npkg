# commander.nari

A port of [commander.js](https://github.com/tj/commander.js) (v15) to the
[Nari](https://github.com/nari-lang/nari) scripting language.

The library reimplements the core of commander.js — commands, options,
arguments, subcommands, help generation, "did you mean" suggestions, and the
action/option parsing pipeline — adapted to Nari's semantics.

The source is split to mirror the original JavaScript layout exactly:

```
commander.nari          (index.js — imports lib/ and re-exports the API)
lib/error.nari           (lib/error.js)
lib/suggestSimilar.nari  (lib/suggestSimilar.js)
lib/argument.nari        (lib/argument.js)
lib/option.nari          (lib/option.js)
lib/help.nari            (lib/help.js)
lib/command.nari         (lib/command.js)
```

Each `lib/*.nari` module uses explicit exports and is imported with Nari's
`import { symbol } from "file.nari"` syntax; `commander.nari` is the single
entry point users import.

## Usage

```nari
import "commander.nari";

let program = create_command("mycli");
program
  .name("mycli")
  .description("do useful things")
  .version("1.0.0")
  .option("-v, --verbose", "verbose output")
  .required_option("-p, --port <n>", "port number")
  .argument("<file>", "input file")
  .action(func(file, options) {
    print("processing " @ file @ " on port " @ options.port);
    if (options.verbose) { print("verbose mode"); }
  });

program.parse();
```

Then:

```
$ nari mycli.nari --help
$ nari mycli.nari -p 8080 data.txt
$ nari mycli.nari -p 8080 data.txt --verbose
```

See `examples/pizza.nari` and `examples/pm.nari` for larger examples
(subcommands, aliases, choices, variadic arguments, custom parsing, ...).

## Public API

The library exports these globals on import:

| Export | Description |
|--------|-------------|
| `program` | A pre-created root `Command` (as in commander.js). |
| `Command(name)` | Factory to create a new command. Call without `new`. |
| `Option(flags, description)` | Factory to create an option. Call without `new`. |
| `Argument(name, description)` | Factory to create an argument. Call without `new`. |
| `Help()` | Factory for the help formatter (override hooks for custom help). |
| `create_command(name)` | Alias for `Command(name)`. |
| `create_option(flags, desc)` | Alias for `Option(flags, desc)`. |
| `create_argument(name, desc)` | Alias for `Argument(name, desc)`. |
| `commander_error(exit_code, code, message)` | Error object passed to `exit_override`. |
| `invalid_argument_error(message)` | Sentinel returned from custom parsers on failure. |

The `Command` surface mirrors commander.js: `.name()`, `.description()`,
`.version()`, `.option()`, `.required_option()`, `.add_option()`, `.argument()`,
`.arguments()`, `.add_argument()`, `.command()`, `.add_command()`, `.action()`,
`.hook()`, `.parse()`, `.parse_async()`, `.opts()`, `.opts_with_globals()`,
`.help()`, `.output_help()`, `.help_information()`, `.help_option()`,
`.help_command()`, `.add_help_text()`, `.alias()`, `.aliases()`, `.usage()`,
`.exit_override()`, `.error()`, `.configure_help()`, `.configure_output()`,
`.allow_unknown_option()`, `.allow_excess_arguments()`, `.enable_positional_options()`,
`.pass_through_options()`, `.combine_flag_and_optional_value()`, `.show_help_after_error()`,
`.show_suggestion_after_error()`, `.on()` / `.emit()` / `.listener_count()`, and the
`Option` / `Argument` builder methods (`.default()`, `.preset()`, `.conflicts()`,
`.implies()`, `.env()`, `.arg_parser()`, `.choices()`, `.make_option_mandatory()`,
`.hide_help()`, `.help_group()`, ...).

## Differences from commander.js

Nari has no exceptions, no classes that can call callbacks from methods, and no
regex/`undefined`. The port adapts accordingly:

- **Constructors are factories.** Use `Command(...)`, `Option(...)`,
  `Argument(...)` without `new` (Nari's `new` only works on classes, and class
  methods cannot call callbacks or see top-level functions). The objects these
  return are closure-based and behave like commander instances.

- **No exceptions / `exit_override`.** commander.js throws `CommanderError` and
  catches `InvalidArgumentError`. Nari has no try/catch, so:
  - `exit_override(callback)` takes a callback invoked with a `commander_error`.
     Return `true` from the callback to suppress `process.exit` (the command is
     then marked aborted and its action will not run). Return nothing/`false` (or
     omit the override) to exit the process via `process.exit`.
   - `_exit` walks up the parent chain to find an `exit_override`, so setting it
     on the root program covers subcommands even when added later.
   - Custom `arg_parser` / `parse_arg` callbacks signal failure by **returning**
     `invalid_argument_error("message")` (instead of throwing). The parser turns
     that into a normal command error. `choices()` validation is built in.

- **`undefined` → `null`.** "Not set" is represented by `null`. A default of
  `null` is treated as "no default" (so it won't show `(default: ...)` in help),
  matching commander's `undefined` handling.

- **Action handler signature.** The action receives the declared arguments
  followed by `options` and the command itself, e.g.
  `func(file, options, command)`. Variadic arguments are collected into a single
  array argument (as in commander) — write `func(files, options)`, not
  `func(...files, options)`.

- **No executable subcommands.** commander.js can dispatch to separate
  executable files; this port only supports action-handler subcommands
  (`.command(name).description(...).action(...)`).

- **No colour / TTY detection.** Help is plain text; `configureOutput` hooks
  (`getOutHasColors`, `stripColor`, ...) are present but default to no colour.

- **Parsing source.** `parse()` with no arguments reads `process.argv`
  (where `argv[0]` is the script path in Nari), skipping it. Pass an array with
  `{ from: "user" }` to parse a bare argument list, as the tests do.

## Known Nari quirks worked around

- Rest parameters (`...rest`) only work in top-level `func` declarations, not in
  object-literal/class methods, so the library routes variadic invocation
  through a top-level `apply_args` helper.
- Spreading a closure-captured array that contains objects fails, so `apply_args`
  copies the array first.
- A `let x = obj.prop; x = x @ ...` on a complex object can write back to
  `obj.prop`; the help code pre-concatenates (`"" @ obj.prop`) to avoid this.

## Running the tests

```bash
./run_tests.sh            # uses ../build/debug/nari
NARI=/path/to/nari ./run_tests.sh
```

## License

Original commander.js is MIT-licensed (TJ Holowaychuk and contributors). This
port follows Nari's project license (GPLv3).
