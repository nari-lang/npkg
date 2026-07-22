#!/usr/bin/env bash
# Run the commander.nari test suite and examples.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
NARI="${NARI:-/home/percs/src/nari/build/debug/nari}"

if [ ! -x "$NARI" ]; then
  if [ -x "$(command -v nari)" ]; then
    NARI="nari"
  else
    echo "nari interpreter not found (looked for $NARI and PATH)" >&2
    exit 1
  fi
fi

cd "$HERE"

run() {
  echo "##### $1 #####"
  "$NARI" "$1" 2>&1
  echo
}

echo "Using interpreter: $NARI"
echo

# Library tests
run tests/test_basic.nari
run tests/test_help.nari
run tests/test_errors.nari
run tests/test_subcommands.nari
run tests/test_features.nari

# Example programs (smoke tests)
echo "##### examples/pizza.nari --help #####"
"$NARI" examples/pizza.nari --help 2>&1
echo
echo "##### examples/pizza.nari -s large -d coke --peppers jalapeno 3 #####"
"$NARI" examples/pizza.nari -s large -d coke --peppers jalapeno 3 2>&1
echo
echo "##### examples/pm.nari --help #####"
"$NARI" examples/pm.nari --help 2>&1
echo
echo "##### examples/pm.nari install -f lodash express chalk #####"
"$NARI" examples/pm.nari install -f lodash express chalk 2>&1
echo
echo "All tests passed."
