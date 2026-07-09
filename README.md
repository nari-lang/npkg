# npkg - Nari package manager

A package manager for Nari, written entirely in Nari.

## Commands

| Command | Description |
|---------|-------------|
| `npkg init [dir] [name]` | Create a new project with `nari.toml` and `src/main.nari` |
| `npkg install [dir]` | Install all deps from `nari.toml` (lockfile-first) |
| `npkg install <pkg[@req]> ...` | Resolve + add named packages from registry into `.` |
| `npkg add [dir] <name@req>` | Add a dep to the manifest and install |
| `npkg update [dir]` | Re-resolve all registry deps within their constraints, refresh lockfile |
| `npkg list [dir]` | Print the installed dep tree |
| `npkg clean [dir]` | Remove store entries not referenced by the lockfile |

## Features

- **Local path deps**: `path = "../my-lib"` in `[dependencies]`
- **Registry deps**: `version = "^1.2.0"` / `"~1.2.0"` / `"1.2.0"` / `"*"`
- **Verified `.tar.gz` archives**: SHA-256 integrity check against the registry-recorded hash on every install
- **Content-addressed store** at `~/.nari/store/pkg/<name>@<version>-<hash>/`
- **Lockfile-first install**: no network hit if `nari.lock.toml` is fresh and all store entries exist
- **Stale lockfile detection**: auto re-resolves when manifest changes
- **Semver ranges**: `^` (compatible), `~` (patch), `*` / empty (latest), exact
- **Transitive deps**: recursive resolution with cycle detection and flat-graph conflict check

## Registry format (`index.toml`)

```toml
registryVersion = 1

[packages."vendor/name"."1.2.3"]
url       = "https://example.com/archives/name-1.2.3.tar.gz"
integrity = "sha256-<hex>"
```

The `registries` field in `nari.toml` must point to the `index.toml` URL directly:

```toml
registries = ["https://example.com/index.toml"]
```

## Quick start (local fixture registry)

```sh
# terminal 1: serve the fixture registry from the repo root
cd npkg-frontend/npkg/fixtures/registry
python -m http.server 8123

# terminal 2: install into the fixture app from the repo root
./build/release/interpreter npkg-frontend/npkg/main.nari install npkg-frontend/npkg/fixtures/registry_app
./build/release/interpreter npkg-frontend/npkg/main.nari list npkg-frontend/npkg/fixtures/registry_app
./build/release/interpreter npkg-frontend/npkg/main.nari update npkg-frontend/npkg/fixtures/registry_app
```

Or with the interpreter on your PATH as `nari`:

```sh
nari npkg-frontend/npkg/main.nari install npkg-frontend/npkg/fixtures/registry_app
```
