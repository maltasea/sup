# The slup Language

This document describes implemented slup syntax plus in-progress syntax aliases.

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
- regex literal: `#"^abc"`
- anonymous function (OCaml runtime): `{$x -> expr}` or `fn($x -> expr)`

## Statements

- Local assignment: `set $x = expr`
- Local assignment aliases: `def $x = expr`, `let $x = expr`
- Global assignment: `$X = expr`
- Array assignment: `set @xs = expr`
- Array assignment aliases: `def @xs = expr`, `let @xs = expr`
- Dict assignment: `set %d = expr`
- Dict assignment aliases: `def %d = expr`, `let %d = expr`
- Return: `return(expr)` or `return()`
- Function call statement: `print("ok")`
- Global declaration: `global $DB_HOST required`
- Global declaration with default: `global $DB_PORT default("5432")`

## Functions

- Non-recursive function: `sub name($a, $b) ... end`
- Non-recursive function alias: `defn name($a, $b) ... end`
- Recursive function: `rec name($n) ... end`
- Parameters are locals and must be lowercase.
- `return(...)` is only valid inside a function.

## Control Flow

### if / when / unless

```slup
if cond
  ...
else
  ...
end
```

- `when cond` behaves like `if cond`.
- `unless cond` executes the first body when `cond` is false.

### switch / case

```slup
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

```slup
while cond
  ...
end
```

- `cond` is re-evaluated each iteration.
- Loop stops when `cond` becomes false.

### foreach / fori

```slup
foreach $v @items
  ...
end
```

```slup
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
- `<block> without matching end` (`if`, `when`, `unless`, `switch`, `while`, `sub`, `foreach`, `fori`)
- `end without matching block`

## Runtime Notes

- Unknown function call is an error.
- In strict globals mode, undeclared global reads/writes are errors.
- Builtins include text/array/dict/file/path/date/time/system helpers and process helpers (`run`, `pipe`, `sh`).
- Runtime parity note: `fn(...)` is currently OCaml-only; Perl parity is pending.
