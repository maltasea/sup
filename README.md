# Esca

Esca is a small scripting language with Perl and OCaml runtimes.

## Quick Start

Run a script with the Perl runtime:

```sh
perl shelm.pl hello.es
```

Build and run the OCaml runtime:

```sh
dune build ./shelm.exe
_build/default/shelm.exe hello.es
```

Release OCaml binary to repo root:

```sh
make release-ocaml
```

## Learn The Language

Canonical source:

- `docs/language-guide.md`

This guide is the primary source for Esca syntax and behavior.

## Generate The HTML Docs Site

Build the website from the canonical guide:

```sh
make docs-site
```

Output:

- `docs/site/index.html`

## Runtime Features

- Line-based parse model with block constructs closed by `end`
- Modules via `load("...")`
- Static global checks via `--check`
- Strict global runtime mode via `--strict-globals`
- Process helpers: `run`, `pipe`, `sh`

Static check example:

```sh
perl shelm.pl --check main.es
```

Strict runtime example:

```sh
perl shelm.pl --strict-globals main.es
```

## Tests

Run all default Perl suites:

```sh
./tests/run-tests.sh
```

Include OCaml parity tests:

```sh
RUN_OCAML_TESTS=1 ./tests/run-tests.sh
```

Key suites:

- `tests/shelm.t`
- `tests/conformance.t`
- `tests/static-check.t`
- `tests/strict-globals.t`
- `tests/shelm-ocaml.t`

## Benchmarks

Quick call-overhead benchmark:

```sh
perl bench/call-overhead.pl --impl perl --calls 20000 --iters 5 --warmup 1
opam exec -- dune build ./shelm.exe
opam exec -- perl bench/call-overhead.pl --impl ocaml --calls 20000 --iters 5 --warmup 1
```

Convenience targets:

```sh
make bench-call-perl
make bench-call-ocaml
```

Extended suite:

```sh
perl bench/overhead-suite.pl --calls 20000 --depth 400 --iters 5 --warmup 1
```

Snapshot and compare:

```sh
make bench
make bench-compare
```
