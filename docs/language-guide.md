# Esca Language Guide

This is the canonical source for learning Esca.

Esca source files use the `.es` extension.

## 1. Quick Start

Run Esca with the Perl runtime:

```sh
perl shelm.pl hello.es
```

Build and run the OCaml runtime:

```sh
dune build ./shelm.exe
_build/default/shelm.exe hello.es
```

## 2. Program Model

- Line-oriented parser: one statement per line (except block forms).
- Blank lines and `# ...` comment lines are ignored.
- Blocks close with `end`.
- Scripts and modules are compiled into an AST before execution.

## 3. Names And Scope

- Locals use lowercase symbols: `$name`, `@items`, `%cfg`.
- Globals use uppercase symbols: `$DB_HOST`, `@ARGS`, `%ENV`.
- Symbols may include `-`, `->`, and `?`.
- Module-qualified symbols use `module/name` (example: `$mod/value`).

Example:

```esca
set $host = "localhost"
$DB_HOST = "localhost"
set @items = ["a", "b"]
set @ARGS = ["x", "y"]
```

## 4. Values

Core value types:

- string
- number
- nil
- array
- dict
- regex

Truthy values are everything except `nil`, empty string, `"0"`, and numeric `0`.

## 5. Statements

Core statement forms:

- `set $x = expr`
- `set @xs = expr`
- `set %d = expr`
- `def $x = expr` and `let $x = expr` (immutable-direction aliases)
- global assignment: `$X = expr`
- function declaration: `defun name(...) ... end`
- recursive function declaration: `rec name(...) ... end`
- function call as statement: `print("ok")`
- `return expr`, `break`, `continue`

Additional statement forms supported in both runtimes:

- `if <expr> then ... [elif <expr> then ...] [else ...] end`
- `while <expr> do ... end`
- `foreach <name> in <expr> do ... end`
- `<name> = <expr>`
- `<name>[<idx>] = <expr>`

## 6. Expressions

Common forms:

- literals: `"txt"`, `123`, `3.14`, `nil`
- arrays: `[1, "a", $x]`
- dicts: `{name: "bernd", age: 88}`
- reads: `$x`, `@xs`, `%d`
- calls: `f(...)` and statement-call sugar `f a, b`
- indexing: `x[i]`
- operators: `== != < > <= >= + - * / % ++ and or not`
- regex operators: `=~`, `!~`, and substitution `=~ s/a/b/g`
- anonymous functions:
  - `fun [x] do ... end`
  - `fun($x -> expr)`
  - `{$x -> expr}`

## 7. Functions

Non-recursive:

```esca
defun add1($x)
  return(add($x, 1))
end
```

Recursive:

```esca
rec fact($n)
  if lt($n, 2)
    return(1)
  end
  return(mul($n, fact(sub($n, 1))))
end
```

## 8. Modules

Load a module:

```esca
load("moda")
```

Rules:

- Extensionless `load("name")` resolves to `.es`.
- Modules execute once per resolved file path.
- Cyclic loads fail with a dependency chain.
- Symbols can be referenced with `module/name` (for example `moda/who("x")`).

## 9. Process And Shell Helpers

Prefer argv-based process APIs:

```esca
set %r = run(["/bin/sh", "-c", "printf ok"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
```

Pipelines:

```esca
set %r = pipe([["/bin/sh", "-c", "printf hi"], ["tr", "a-z", "A-Z"]])
print(dict-get(%r, "out"))
```

`sh(cmd)` exists for shell-string commands, but `run(...)` and `pipe(...)` are preferred.

## 10. Globals Validation Modes

Static check:

```sh
perl shelm.pl --check main.es
```

Strict runtime mode:

```sh
perl shelm.pl --strict-globals main.es
```

Global declarations:

```esca
global $DB_HOST required
global $DB_PORT default("5432")
```

## 11. Builtin Naming Direction

Preferred aliases:

- text: `text->len`, `text->upper`, `text->lower`
- arrays: `array->len`, `array->get`, `array->push`
- dicts: `dict->get`, `dict->set`, `dict->keys`
- file/dir: `file->text`, `text->file`, `file->exists`, `dir->entries`
- path: `path->join`

Legacy names remain available for compatibility where implemented.

## 12. Where To Learn By Example

- `hello.es` for a minimal script
- `tests/shelm.t` for feature-level behavior
- `tests/conformance.t` for parser/runtime parity cases
- `tests/static-check.t` and `tests/strict-globals.t` for global validation behavior

