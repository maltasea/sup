# slup

`slup` is a small scripting language interpreter.

Main entrypoints:
- Perl: `perl slup.pl <script.slup>`
- OCaml build: `dune build ./slup.exe` then `_build/default/slup.exe <script.slup>`

Release OCaml binary to repo root:
- `make release-ocaml` (writes `./slup`)

Execution model:
- line-based parse (one line = one statement, except block constructs)
- scripts/modules are compiled into a simple AST before execution

## Syntax Direction (Planned)

Target syntax direction:
- `def` for immutable top-level/module bindings
- `let` for immutable local short-lived bindings
- `set` as the only mutating form (updates existing bindings)
- `defun` for named function definitions
- `fun` for anonymous functions

Status note:
- Perl and OCaml runtimes accept `def`, `let`, and `defun` (`defn` removed).
- Perl and OCaml runtimes accept `fun(...)` (`fn(...)` removed).
- Perl and OCaml runtimes accept Mini Shelm Light statement forms:
  - `if <expr> then ... [elif <expr> then ...] [else ...] end`
  - `while <expr> do ... end`
  - `foreach <name> in <expr> do ... end`
  - `<name> = <expr>` and `<name>[<idx>] = <expr>`
  - `break`, `continue`, `return <expr>`
- Perl and OCaml runtimes accept Mini Shelm Light expression forms:
  - calls: `f(...)` and statement-call sugar `f a, b`
  - block lambdas: `fun [params] do ... end`
  - infix operators: `== != < > <= >= + - * / % ++ and or not`
  - regex operators: `=~`, `!~`, and `=~ s/.../.../g`
  - `nil`, array/dict literals, and keyword dict keys (`name:`)
- Full immutability semantics migration is still in progress.

## Globals vs Locals

Name rules:
- Globals: uppercase symbols (for example: `$DB_HOST`, `@ARGS`, `%ENV`, `$MY-GLOBAL?`)
- Locals: lowercase symbols (for example: `$host`, `@items`, `%cfg`)

Supported symbol characters include:
- `-`
- `->`
- `?`

Examples:

```slup
set $host = "localhost"   # local
$DB_HOST = "localhost"    # global
set @items = ["a", "b"]   # local array
set @ARGS = ["x", "y"]    # global array
```

## Declaring Globals

You can declare globals explicitly:

```slup
global $DB_HOST required
global $DB_PORT default("5432")
```

Declaration modifiers:
- `required`
- `default(<expr>)`

## Recursion

Function recursion must be explicit:
- `defun name(...)` defines a non-recursive function
- `rec name(...)` defines a recursive function

Examples:

```slup
defun add1($x)
  return(add($x, 1))
end

rec fact($n)
  if lt($n, 2)
    return(1)
  end
  return(mul($n, fact(sub($n, 1))))
end
```

Current naming direction:
- `defun` for named functions (`sub` removed in Perl runtime)
- `fun` for anonymous functions (`fn` removed in Perl runtime)

## Static Checking

Use static mode to verify global declarations/assignments without executing the script:

```sh
perl slup.pl --check main.slup
```

`--check` enforces:
- uppercase global declarations
- no undeclared global assignments
- required globals must be assigned (unless they have `default(...)`)

It recursively scans `load("...")` when the load target is a string literal.

Limitation:
- dynamic loads (for example `load($path)`) are rejected in static mode because they cannot be resolved statically.

## Strict Runtime Mode

Use strict mode to enforce global declarations at runtime:

```sh
perl slup.pl --strict-globals main.slup
```

`--strict-globals` does:
- startup static precheck (`--check` behavior)
- runtime error on undeclared global read/assignment
- runtime required-global validation after execution

Built-in globals predeclared by the interpreter:
- `$PATH`
- `$ARG1`, `$ARG2`, ...
- `@ARGS`
- `%ENV`

## Modules and Namespacing

Load modules:

```slup
load("moda")
```

`load()` behavior:
- modules are executed once per resolved file path (subsequent `load(...)` calls reuse loaded module state)
- cyclic loads fail fast with a clear dependency chain
- loading two different files with the same module basename (for example two `alpha.slup` files) fails with a module-name collision error

Module-local symbols are namespaced:
- function call: `moda/who("x")`
- variable read: `$moda/value`
- array read: `@moda/items`
- dict read: `%moda/cfg`

Main module symbols stay callable without module prefix.

## Shell Commands

Use `run` for one command (argv form, no shell parsing):

```slup
set %r = run(["/bin/sh", "-c", "printf ok; printf warn 1>&2"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
```

Use `pipe` for command pipelines:

```slup
set %r = pipe([["/bin/sh", "-c", "printf hi"], ["tr", "a-z", "A-Z"]])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
```

Both return a dict:
- `code` (exit status; for pipelines, the last command)
- `out` (captured stdout)
- `err` (captured stderr)

`sh(cmd)` remains available for shell-string commands, but by default rejects shell metacharacters.
- For shell metacharacters, prefer `run(...)` or `pipe(...)`.
- If you intentionally need shell metacharacters, pass an explicit override: `sh("echo ok | cat", 1)`.

Use `stderr(...)` for explicit stderr output.

## API Naming

Preferred built-in names use directional/style-consistent aliases:
- text: `text->len`, `text->upper`, `text->lower`
- arrays: `array->len`, `array->get`, `array->push`, `array->pop`
- dicts: `dict->get`, `dict->set`, `dict->keys`, `dict->has`, `dict->del`
- files/dirs: `file->text`, `text->file`, `file->append`, `file->lines`, `lines->file`, `file->exists`, `file->remove`, `dir->exists`, `dir->entries`, `dir->cwd`, `dir->chdir`
- paths: `path->join`

Legacy names remain supported for compatibility.

## Tests

Run all tests:

```sh
./tests/run-tests.sh
```

`tests/run-tests.sh` runs the Perl suites by default.
To include OCaml parity tests:

```sh
RUN_OCAML_TESTS=1 ./tests/run-tests.sh
```

Key test suites:
- `tests/slup.t`
- `tests/conformance.t`
- `tests/static-check.t`
- `tests/strict-globals.t`
- `tests/slup-ocaml.t`

## Benchmark

Quick call-overhead benchmark:

```sh
perl bench/call-overhead.pl --impl perl --calls 20000 --iters 5 --warmup 1
opam exec -- dune build ./slup.exe
opam exec -- perl bench/call-overhead.pl --impl ocaml --calls 20000 --iters 5 --warmup 1
```

It compares:
- baseline loop with no user-function call
- equivalent loop that calls a user-defined function each iteration

Convenience targets:

```sh
make bench-call-perl
make bench-call-ocaml
```

Extended overhead benchmark suite:

```sh
perl bench/overhead-suite.pl --calls 20000 --depth 400 --iters 5 --warmup 1
```

It reports:
- recursion call overhead vs a loop baseline
- module-qualified calls (`mod/f(...)`) vs local function calls
- strict globals runtime cost (`--strict-globals`) vs normal mode

Append a dated benchmark snapshot:

```sh
make bench
```

`make bench` runs the overhead suite and appends results to `bench/baseline.md`.
It also prints a comparison against the previous baseline snapshot.
Each run also writes a machine-readable JSON snapshot to `bench/history/<timestamp>.json`.

Optional overrides:

```sh
make bench BENCH_CALLS=20000 BENCH_DEPTH=400 BENCH_ITERS=5 BENCH_WARMUP=1
```

Compare the latest two snapshots without running a new benchmark:

```sh
make bench-compare
```

`make bench-compare` reads the latest two files in `bench/history/`.

Fail if latest snapshot regressed beyond thresholds:

```sh
make bench-guard
```

Default max regression thresholds are 10% per metric.

Threshold overrides:

```sh
make bench-guard BENCH_MAX_REC_PCT=4 BENCH_MAX_MOD_PCT=3 BENCH_MAX_STRICT_PCT=2
```

`make bench-guard` also reads from `bench/history/`.
