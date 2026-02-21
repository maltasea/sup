# SLUP AI Handoff

This document captures implementation context for AI assistants working on the slup codebase. It complements the README and test suites.

## Dual Implementations

| | Perl | OCaml |
|---|---|---|
| Entry | `perl slup.pl <script>` | `_build/default/slup.exe <script>` |
| Build | none | `opam exec -- dune build ./slup.exe` |
| Release binary | n/a | `make release-ocaml` (writes `./slup`) |

Both interpreters should accept the same language. When adding features, implement in both and verify with the shared test suite.

## Syntax Direction (Current + In Progress)

- Accepted aliases in both runtimes:
  - `def` / `let` for assignment forms currently parsed alongside `set`
  - `defn` parsed alongside `sub`
- In progress:
  - full `def`/`let` immutability semantics
  - `fn(...)` parity in Perl runtime (currently OCaml-only)

## Architecture (OCaml — `slup.ml`)

Single-file interpreter (~3000 lines). Key sections in order:

1. **Types** — `value`, `dynarr`, `dict_key`, `expr` are mutually recursive. `node` and `sub_def` follow.
2. **Value helpers** — `to_str`, `to_num`, `is_truthy` (update these when adding value variants).
3. **Global state** — module variable frames, globals, builtins hashtable.
4. **Compiler** — `compile_expr` turns strings into `expr` AST; `compile_block`/`compile_node` build `node` lists.
5. **Evaluator** — `eval_expr` (recursive) and `exec_node` (statement dispatch). `run_nodes` drives block execution.
6. **Builtins** — `register_builtins()` populates the `builtins` hashtable. Organized by section: Math, String, Comparison, Regex, Array, Dict, Array helpers, Functional, File I/O, Process, Shell. Aliases at the bottom.
7. **Main** — argv parsing, `--check`, `--strict-globals`.

### Variable scoping

- **Globals**: uppercase names, stored in `globals`/`global_arrays`/`global_dicts` hashtables.
- **Locals**: lowercase names, stored in per-module frame stacks (`module_var_frames`). `push_module_var_frame` / `pop_module_var_frame` manage scope for sub calls and lambdas.

### Adding a new builtin

```ocaml
add "name" (fun a ->
  let x = nth_num a 0 in   (* nth_str, nth_val also available *)
  Num (x +. 1.0));
```

For builtins that require a specific type, use `require_arr`, `require_dict`, or `require_lambda`.

### Adding a new value type

1. Add variant to `value` type.
2. Add cases to `to_str`, `to_num`, `is_truthy`.
3. Handle in `eval_expr` if there's a corresponding `expr` variant.

## Lambdas and Higher-Order Functions

Added in the OCaml sync (Feb 2026). Lambdas are first-class values.

### Syntax

```slup
{$x -> mul($x, 2)}
{$a, $b -> add($a, $b)}
```

Parsed in `compile_expr` inside the `{...}` branch: if the inner content starts with `$` and contains `->` at depth 0, it's a lambda; otherwise it falls through to dict literal parsing.

### Implementation

- `ELambda of string list * expr` — AST node (captures param names + compiled body)
- `Lambda of string list * expr` — runtime value (same data, lives in `value` type)
- `invoke_lambda` — pushes a fresh scope frame on the current module, binds params, evaluates body, pops frame. Exception-safe.

### Available HOFs

All take `(array, lambda)` except `reduce` which takes `(array, init, lambda)` and `apply` which takes `(lambda, args...)`.

| Function | Returns | Description |
|---|---|---|
| `map` | array | Transform each element |
| `filter` | array | Keep elements where lambda is truthy |
| `reject` | array | Drop elements where lambda is truthy |
| `reduce` | value | Fold with accumulator |
| `find` | value/nil | First truthy match |
| `any` | 0/1 | At least one truthy |
| `all` | 0/1 | All truthy |
| `none` | 0/1 | No truthy |
| `count` | number | Count truthy matches |
| `each` | array | Side-effect iteration, returns original array |
| `flat-map` | array | Map then flatten one level |
| `sort-by` | array | Sort by string key from lambda |
| `group-by` | dict | Group into dict of arrays by key |
| `uniq-by` | array | Deduplicate by key |
| `apply` | value | Invoke lambda with explicit args |

## Array Helpers

| Function | Signature | Notes |
|---|---|---|
| `sort(arr)` | string comparison | |
| `reverse(arr)` | | |
| `uniq(arr)` | string-key dedup | |
| `flatten(arr)` | one level | |
| `zip(a, b)` | array of 2-element arrays | min length |
| `take(arr, n)` | first n | |
| `drop(arr, n)` | skip first n | |
| `chunk(arr, n)` | array of sub-arrays | |
| `range(from, to)` | inclusive, auto-direction | |
| `sum(arr)` | numeric sum | |
| `min(arr)` | numeric min | |
| `max(arr)` | numeric max | |

## Operators Added

| Name | Type | Notes |
|---|---|---|
| `div(a, b)` | math | Zero-check |
| `mod(a, b)` | math | `mod_float`, zero-check |
| `ne(a, b)` | comparison | String inequality |
| `ge(a, b)` | comparison | Numeric >= |
| `le(a, b)` | comparison | Numeric <= |
| `and(a, b)` | logic | Both truthy |
| `or(a, b)` | logic | Either truthy |
| `true()` | constant | Returns 1 |
| `false()` | constant | Returns 0 |

## Process Builtins

| Name | Notes |
|---|---|
| `sleep(seconds)` | `Unix.sleepf`, clamps negative to 0 |
| `kill(signal, pid)` | `Unix.kill` |
| `wait(pid)` | Returns dict with pid/status/code/signal |
| `times()` | Returns 4-element array (user/sys/cuser/csys) |
| `umask(mode?)` | Get (no arg) or set |

## Aliases

```
pwd  -> cwd
cd   -> chdir
read -> user-input
```

## Test Strategy

- `tests/slup.t` — Perl-only core tests
- `tests/conformance.t` — Perl-only conformance (modules, shell, sys, aliases)
- `tests/slup-ocaml.t` — OCaml parity (mirrors slup.t + conformance.t)
- `tests/static-check.t` — `--check` mode
- `tests/strict-globals.t` — `--strict-globals` mode

Run all: `./tests/run-tests.sh` (set `RUN_OCAML_TESTS=1` for OCaml suite).

The OCaml test file (`slup-ocaml.t`) builds the binary via `dune build` at the top, then runs each test case through a temp file.

## Parity Gaps

Features in OCaml not yet in Perl (as of Feb 2026):
- Lambdas and all HOFs (`map`, `filter`, `reduce`, etc.)
- Array helpers (`sort`, `reverse`, `range`, `zip`, etc.)
- `div`, `mod`, `ne`, `ge`, `le`, `and`, `or`
- `true`, `false`
- `sleep`, `kill`, `wait`, `times`, `umask` (Perl has these but via different code paths)
- `pwd`, `cd`, `read` aliases

When syncing Perl to match, the test programs in this doc's examples should produce identical output from both interpreters.
