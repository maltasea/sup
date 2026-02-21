# POSIX Shell Built-in Commands

## Special Built-ins

These **must** be built-in per POSIX. They cause the script to abort on error
(in non-interactive shells), and variable assignments persist after the command.

| Command      | Description                                      |
|--------------|--------------------------------------------------|
| `:`          | Null command (always returns true)                |
| `.`          | Source/execute a file in the current environment  |
| `break`      | Exit from a `for`, `while`, or `until` loop       |
| `continue`   | Skip to next iteration of a loop                  |
| `eval`       | Construct and execute a command from arguments     |
| `exec`       | Replace shell with command, or redirect shell I/O |
| `exit`       | Exit the shell with a status                      |
| `export`     | Set environment variables for child processes      |
| `readonly`   | Mark variables as unmodifiable                     |
| `return`     | Return from a function or sourced script           |
| `set`        | Set/unset shell options and positional parameters  |
| `shift`      | Shift positional parameters                        |
| `times`      | Print accumulated user and system times            |
| `trap`       | Set signal handlers                                |
| `unset`      | Unset variables or functions                       |

## Regular Built-ins

Commonly built-in but not required to be by POSIX.

| Command      | Description                                       |
|--------------|---------------------------------------------------|
| `alias`      | Define or display command aliases                  |
| `bg`         | Resume a job in the background                     |
| `cd`         | Change the working directory                       |
| `command`    | Execute a command, bypassing shell functions        |
| `false`      | Return a non-zero (failure) exit status            |
| `fc`         | Process the command history                        |
| `fg`         | Resume a job in the foreground                     |
| `getopts`    | Parse positional parameters as options             |
| `hash`       | Remember command locations                         |
| `jobs`       | Display background job status                      |
| `kill`       | Send signals to processes                          |
| `newgrp`     | Change the current group ID                        |
| `pwd`        | Print the working directory                        |
| `read`       | Read a line from standard input                    |
| `true`       | Return a zero (success) exit status                |
| `type`       | Describe how a command name is interpreted          |
| `ulimit`     | Get or set resource limits                         |
| `umask`      | Get or set the file mode creation mask             |
| `unalias`    | Remove alias definitions                           |
| `wait`       | Wait for background processes to complete          |

## Function Definition Syntax

POSIX only supports this form (no `function` keyword):
```sh
