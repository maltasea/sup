#!/usr/bin/env sh
set -eu
prove -v tests/slup.t tests/conformance.t tests/static-check.t tests/strict-globals.t

if [ "${RUN_OCAML_TESTS:-0}" = "1" ]; then
  prove -v tests/slup-ocaml.t
fi
