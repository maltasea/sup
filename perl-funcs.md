# Perl Built-in Functions

## String Functions

| Function | Description |
|----------|-------------|
| `chomp` | Remove trailing newline |
| `chop` | Remove last character |
| `chr` | Character from numeric value |
| `crypt` | One-way password hashing |
| `fc` | Foldcase for case-insensitive comparison |
| `hex` | Convert hex string to number |
| `index` | Find substring position (left to right) |
| `lc` | Lowercase string |
| `lcfirst` | Lowercase first character |
| `length` | Length of string |
| `oct` | Convert octal/binary/hex string to number |
| `ord` | Numeric value of character |
| `pack` | Convert values to binary structure |
| `reverse` | Reverse string or list |
| `rindex` | Find substring position (right to left) |
| `sprintf` | Formatted string |
| `substr` | Extract or replace substring |
| `uc` | Uppercase string |
| `ucfirst` | Uppercase first character |
| `unpack` | Extract values from binary structure |

## Regular Expressions

| Function | Description |
|----------|-------------|
| `pos` | Position of last `m//g` match |
| `quotemeta` | Escape metacharacters |
| `split` | Split string by pattern |
| `study` | Optimize pattern matching (deprecated) |

## Numeric Functions

| Function | Description |
|----------|-------------|
| `abs` | Absolute value |
| `atan2` | Arctangent of Y/X |
| `cos` | Cosine |
| `exp` | e to the power of |
| `int` | Truncate to integer |
| `log` | Natural logarithm |
| `rand` | Random number [0, n) |
| `sin` | Sine |
| `sqrt` | Square root |
| `srand` | Seed random number generator |

## Array / List Functions

| Function | Description |
|----------|-------------|
| `each` | Next key/value pair from array |
| `grep` | Filter list by expression |
| `join` | Join list into string |
| `keys` | Array indices |
| `map` | Transform list |
| `pop` | Remove last element |
| `push` | Append elements |
| `reverse` | Reverse list |
| `shift` | Remove first element |
| `sort` | Sort list |
| `splice` | Add/remove elements at position |
| `unshift` | Prepend elements |
| `values` | Array values |
| `wantarray` | Check calling context |

## Hash Functions

| Function | Description |
|----------|-------------|
| `delete` | Remove key/value pair |
| `each` | Next key/value pair |
| `exists` | Check if key exists |
| `keys` | All keys |
| `values` | All values |

## I/O Functions

| Function | Description |
|----------|-------------|
| `binmode` | Set binary mode on filehandle |
| `close` | Close filehandle |
| `closedir` | Close directory handle |
| `dbmclose` | Close DBM file |
| `dbmopen` | Open DBM file |
| `die` | Raise exception / exit with error |
| `eof` | Test for end of file |
| `fileno` | File descriptor from filehandle |
| `flock` | Lock/unlock file |
| `format` | Define output format |
| `getc` | Read single character |
| `glob` | Expand filename patterns |
| `open` | Open file/pipe/handle |
| `opendir` | Open directory handle |
| `print` | Output to filehandle |
| `printf` | Formatted output |
| `read` | Read bytes from filehandle |
| `readdir` | Read directory entries |
| `readline` | Read line from filehandle (`<>`) |
| `rewinddir` | Reset directory handle |
| `say` | Print with newline (5.10+) |
| `seek` | Set position in file |
| `seekdir` | Set position in directory |
| `select` | Set default output / I/O multiplexing |
| `stat` | File status info |
| `tell` | Current position in file |
| `telldir` | Current position in directory |
| `truncate` | Shorten file |
| `warn` | Print warning message |
| `write` | Output formatted record |

## File Operations

| Function | Description |
|----------|-------------|
| `-X` | File test operators (`-e`, `-f`, `-d`, `-r`, `-w`, etc.) |
| `chdir` | Change directory |
| `chmod` | Change file permissions |
| `chown` | Change file ownership |
| `chroot` | Change root directory |
| `fcntl` | File control |
| `ioctl` | Device control |
| `link` | Create hard link |
| `lstat` | Stat a symbolic link |
| `mkdir` | Create directory |
| `readlink` | Read symbolic link target |
| `rename` | Rename file |
| `rmdir` | Remove directory |
| `symlink` | Create symbolic link |
| `umask` | Set file creation mask |
| `unlink` | Delete file |
| `utime` | Set file timestamps |

## Flow Control

| Function | Description |
|----------|-------------|
| `caller` | Info about calling subroutine |
| `continue` | Continue block after loop |
| `die` | Raise exception |
| `do` | Execute file or block |
| `dump` | Create core dump |
| `eval` | Evaluate string/block as code |
| `evalbytes` | Evaluate byte string as code |
| `exit` | Exit program |
| `goto` | Jump to label/subroutine |
| `last` | Exit loop (like `break`) |
| `next` | Next loop iteration (like `continue` in C) |
| `redo` | Restart loop iteration |
| `return` | Return from subroutine |
| `sub` | Define subroutine |
| `wantarray` | Check list/scalar context |

## Scoping

| Function | Description |
|----------|-------------|
| `local` | Temporary (dynamic) scoping |
| `my` | Lexical scoping |
| `our` | Package-level lexical |
| `state` | Persistent lexical variable (5.10+) |

## References & Object-Oriented

| Function | Description |
|----------|-------------|
| `bless` | Associate reference with class |
| `ref` | Type of reference |
| `tie` | Bind variable to class |
| `tied` | Get object behind tied variable |
| `untie` | Remove tie binding |

## Process & System

| Function | Description |
|----------|-------------|
| `alarm` | Schedule SIGALRM |
| `exec` | Replace process with command |
| `fork` | Create child process |
| `getpgrp` | Get process group |
| `getppid` | Get parent PID |
| `getpriority` | Get process priority |
| `kill` | Send signal to process |
| `pipe` | Create pipe pair |
| `setpgrp` | Set process group |
| `setpriority` | Set process priority |
| `sleep` | Pause execution |
| `system` | Run external command |
| `times` | Process times (user/system) |
| `wait` | Wait for child process |
| `waitpid` | Wait for specific child |

## Socket Functions

| Function | Description |
|----------|-------------|
| `accept` | Accept incoming connection |
| `bind` | Bind socket to address |
| `connect` | Connect to remote socket |
| `getpeername` | Remote address of socket |
| `getsockname` | Local address of socket |
| `getsockopt` | Get socket option |
| `listen` | Listen for connections |
| `recv` | Receive data |
| `send` | Send data |
| `setsockopt` | Set socket option |
| `shutdown` | Shut down socket |
| `socket` | Create socket |
| `socketpair` | Create socket pair |

## System V IPC

| Function | Description |
|----------|-------------|
| `msgctl` | Message queue control |
| `msgget` | Get message queue ID |
| `msgrcv` | Receive message |
| `msgsnd` | Send message |
| `semctl` | Semaphore control |
| `semget` | Get semaphore set ID |
| `semop` | Semaphore operations |
| `shmctl` | Shared memory control |
| `shmget` | Get shared memory ID |
| `shmread` | Read shared memory |
| `shmwrite` | Write shared memory |

## User & Group Info

| Function | Description |
|----------|-------------|
| `endgrent` | Close group file |
| `endhostent` | Close hosts file |
| `endnetent` | Close networks file |
| `endpwent` | Close password file |
| `endprotoent` | Close protocols file |
| `endservent` | Close services file |
| `getgrent` | Next group entry |
| `getgrgid` | Group entry by GID |
| `getgrnam` | Group entry by name |
| `gethostbyaddr` | Host entry by address |
| `gethostbyname` | Host entry by name |
| `gethostent` | Next host entry |
| `getlogin` | Current login name |
| `getnetbyaddr` | Network entry by address |
| `getnetbyname` | Network entry by name |
| `getnetent` | Next network entry |
| `getpwent` | Next password entry |
| `getpwnam` | Password entry by name |
| `getpwuid` | Password entry by UID |
| `getprotobyname` | Protocol entry by name |
| `getprotobynumber` | Protocol entry by number |
| `getprotoent` | Next protocol entry |
| `getservbyname` | Service entry by name |
| `getservbyport` | Service entry by port |
| `getservent` | Next service entry |
| `setgrent` | Rewind group file |
| `sethostent` | Rewind hosts file |
| `setnetent` | Rewind networks file |
| `setpwent` | Rewind password file |
| `setprotoent` | Rewind protocols file |
| `setservent` | Rewind services file |

## Time Functions

| Function | Description |
|----------|-------------|
| `gmtime` | Convert time to UTC components |
| `localtime` | Convert time to local components |
| `time` | Current epoch time |

## Miscellaneous

| Function | Description |
|----------|-------------|
| `defined` | Check if value is defined |
| `formline` | Format line for `write` |
| `lock` | Thread lock on variable |
| `prototype` | Get subroutine prototype |
| `reset` | Reset `??` searches |
| `scalar` | Force scalar context |
| `undef` | Undefine a variable |

## Special Tokens

| Token | Description |
|-------|-------------|
| `__FILE__` | Current filename |
| `__LINE__` | Current line number |
| `__PACKAGE__` | Current package name |
| `__SUB__` | Reference to current subroutine (5.16+) |
| `__END__` | End of code, start of data |
| `__DATA__` | End of code, start of data (per-package) |

---

**Reference:** [perldoc perlfunc](https://perldoc.perl.org/perlfunc)
