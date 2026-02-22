# The shelm Language

This document describes implemented shelm syntax plus the current Mini Shelm Light surface supported by the Perl and OCaml runtimes.

## Program Model

- A script is line-based: one statement per line.
- Blank lines and lines starting with `#` are ignored.
- Block forms are closed with `end`.
- Scripts are compiled to an AST, then executed.

## Names and Scope

- Locals must be lowercase symbols: `$name`, `@items`, `%cfg`.
- Globals must be uppercase symbols: `$DB_HOST`, `@ARGS`, `%ENV`.
- Symbols may include `-`, `->`, and `?`.
- Module-qualified symbols use `module/name`, for example `$mod/value`.

## Values

Core value kinds:

- string
- number
- nil
- array
- dict
- regex (`#"...pattern..."`)

Truthiness:

- false: `nil`, `""`, `"0"`, numeric `0`
- true: everything else

## Expressions

Supported expression forms:

- string literal: `"hello"`
- number literal: `123`, `3.14`
- var/array/dict read: `$x`, `@xs`, `%d`
- array literal: `[1, "a", $x]`
- dict literal: `{k: "v", "api-key": 1, $dyn_key: 2}`
- function call: `add(1, 2)`
- Mini Shelm call sugar (Perl and OCaml runtimes): `print add(1, 2)` (statement form)
- regex literal: `#"^abc"`
- anonymous function: `{$x -> expr}` or `fun($x -> expr)`
- Mini Shelm block lambda (Perl and OCaml runtimes): `fun [x] do ... end`
- Mini Shelm infix forms (Perl and OCaml runtimes): `a + b`, `a == b`, `a and b`, `not a`
- Mini Shelm regex forms (Perl and OCaml runtimes): `x =~ /pat/`, `x !~ /pat/`, `x =~ s/a/b/g`
- Mini Shelm indexing (Perl and OCaml runtimes): `x[i]` for arrays and dicts
- Mini Shelm literal names (Perl and OCaml runtimes): `name:` inside dict literals

## Statements

- Local assignment: `set $x = expr`
- Local assignment aliases: `def $x = expr`, `let $x = expr`
- Global assignment: `$X = expr`
- Array assignment: `set @xs = expr`
- Array assignment aliases: `def @xs = expr`, `let @xs = expr`
- Dict assignment: `set %d = expr`
- Dict assignment aliases: `def %d = expr`, `let %d = expr`
- Return: `return(expr)` or `return()`
- Mini Shelm return form (Perl and OCaml runtimes): `return expr`
- Function call statement: `print("ok")`
- Mini Shelm statement aliases (Perl and OCaml runtimes):
  - `if expr then ... [elif expr then ...] [else ...] end`
  - `while expr do ... end`
  - `foreach name in expr do ... end`
  - `name = expr`
  - `name[index] = expr`
  - `break` / `continue`
- Global declaration: `global $DB_HOST required`
- Global declaration with default: `global $DB_PORT default("5432")`

## Functions

- Non-recursive function: `defun name($a, $b) ... end`
- Recursive function: `rec name($n) ... end`
- Parameters are locals and must be lowercase.
- `return(...)` is only valid inside a function.

## Control Flow

### if / when / unless

```shelm
if cond
  ...
else
  ...
end
```

- `when cond` behaves like `if cond`.
- `unless cond` executes the first body when `cond` is false.

### switch / case

```shelm
switch expr
case value1
  ...
case value2
  ...
else
  ...
end
```

- Cases are checked top-to-bottom.
- First matching case runs; remaining cases are skipped.
- If no case matches, `else` runs when present.
- `case` is only valid inside `switch`.

### while

```shelm
while cond
  ...
end
```

- `cond` is re-evaluated each iteration.
- Loop stops when `cond` becomes false.

### foreach / fori

```shelm
foreach $v @items
  ...
end
```

```shelm
fori $v @items
  ...
end
```

- Iterates over an array snapshot from index `0` upward.
- `fori` additionally sets local `$i` to the current index each iteration.

## Modules

- Load module file: `load("name")` or `load("path/name")`.
- Module code executes once per resolved path.
- Functions and local symbols can be referenced with `module/name`.
- Globals are shared across modules.

## Common Parse Errors

- `else without matching if`
- `case without matching switch`
- `<block> without matching end` (`if`, `when`, `unless`, `switch`, `while`, `defun`, `rec`, `foreach`, `fori`)
- `end without matching block`

## Runtime Notes

- Unknown function call is an error.
- In strict globals mode, undeclared global reads/writes are errors.
- Builtins include text/array/dict/file/path/date/time/system helpers and process helpers (`run`, `pipe`, `sh`).
- Runtime note: Perl and OCaml runtimes support `fun(...)`, `fun [..] do ... end`, and `{$x -> ...}` lambda forms.
