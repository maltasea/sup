# Slup Mapping For `perl-funcs.md` and `shell-posix-builtins.md`

This maps Perl function families to Slup for a shell-first language.

## Policy

- Slup core stays procedural and shell-focused.
- OOP crossing is blocked in the Perl bridge (`perl.call` rejects blessed refs in args/results).
- Prefer native Slup built-ins for common scripting tasks.
- Use `sys(...)` for advanced POSIX or external Perl modules.

## Native Slup (Built-in)

- File write/read/check:
  - `text->file`, `file->append`, `file->text`, `file->lines`, `lines->file`, `file->exists`, `file->remove`
- Directory operations:
  - `mkdir`, `dir->exists`, `dir->entries`, `dir->list`, `dir->cwd`, `dir->chdir`
- Path checks/types:
  - `path->join`, `path->basename`, `path->dirname`, `path->type`, `path->is-file`, `path->is-dir`, `path->is-socket`, `path->is-link`
- Process execution:
  - `run`, `pipe`, `sh`, `stderr`
- Time/date:
  - `date->today`, `time->now`, `time->iso-utc`
- Shell compatibility:
  - `pwd`, `cd`, `true`, `false`, `sleep`, `umask`, `times`, `kill`, `wait`
- String/array/dict basics:
  - `text->len`, `text->upper`, `text->lower`, `text->replace`, `text->replace-all`
  - `array->len`, `array->get`, `array->push`, `array->pop`
  - `dict->get`, `dict->set`, `dict->keys`, `dict->has`, `dict->del`

## `sys(...)` POSIX Capabilities

- `posix.getpid`, `posix.getppid`
- `posix.stat`, `posix.lstat`, `posix.realpath`
- `posix.access`
- `posix.readlink`, `posix.symlink`, `posix.unlink`
- `posix.mkdir`, `posix.rmdir`, `posix.chmod`, `posix.utime`

## External Perl Modules (Non-OO Bridge)

- `perl.module.require`
- `perl.module.can`
- `perl.call`

Examples:

```sup
set %h = sys("perl.call", "Digest::SHA", "sha256_hex", ["abc"])
print(dict-get(%h, "result"))
```

## Out Of Scope For Core Slup

These stay out of core unless there is repeated shell-first demand:

- Perl scoping/control internals:
  - `my`, `our`, `local`, `wantarray`, `goto`, `redo`, `dump`, `evalbytes`, tokens like `__PACKAGE__`
- Perl OO internals:
  - `bless`, `tie`, `tied`, `untie`
- Perl-specific context/meta behavior:
  - `caller`, `prototype`, `formline`, `reset`
- System V IPC and niche APIs:
  - `msg*`, `sem*`, `shm*`, low-level DBM APIs
- Shell job-control/history internals:
  - `bg`, `fg`, `jobs`, `fc`, `hash`, `alias`, `unalias`

## From `perl-funcs.md` To Slup: Practical Rule

- Needed often in shell scripts: add/keep native Slup built-in.
- Powerful but platform-specific: expose via `sys(...)` capability.
- Perl-internal language mechanics: do not mirror in Slup.
