#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Spec;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);

my $slup = File::Spec->catfile($Bin, '..', 'slup.pl');

sub write_text {
    my ($path, $content) = @_;
    my ($vol, $dir, undef) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

sub run_file {
    my ($path) = @_;
    my $cmd = qq{perl "$slup" "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    return $data;
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
set $name = "alpha"
sub who($x)
  return(concat(concat($name, ":"), $x))
end
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set $name = "main"
sub who($x)
  return(concat(concat($name, ":"), $x))
end
load("alpha")
print(who("A"))
print(alpha/who("B"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'qualified and unqualified function calls execute');
    is($out, "main:A\nalpha:B\n", 'main stays unqualified, module requires qualification');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
sub only_alpha()
  return("x")
end
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
load("alpha")
print(only_alpha())
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'module-only function is not available unqualified');
    like($out, qr/Unknown function: only_alpha/, 'unqualified module-only function fails clearly');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
$G = "from-module"
sub getg()
  return($G)
end
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
$G = "from-main"
load("alpha")
print($G)
print(alpha/getg())
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'global variables are shared across modules');
    is($out, "from-module\nfrom-module\n", 'global value is shared and visible in both main and module');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
set $v = "module-local"
set @items = ["a", "b", "c"]
set %cfg = {k: "v"}
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set $v = "main-local"
load("alpha")
print($v)
print($alpha/v)
print(len(@alpha/items))
print(dict-get(%alpha/cfg, "k"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'qualified var/array/dict access executes');
    is($out, "main-local\nmodule-local\n3\nv\n", 'module symbols stay scoped and are reachable through module/name');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'mods', 'helper.slup'), <<'SLUP');
sub ping()
  return("pong")
end
SLUP
    write_text(File::Spec->catfile($dir, 'mods', 'alpha.slup'), <<'SLUP');
load("helper")
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
load("mods/alpha")
print(helper/ping())
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'relative load from inside a module executes');
    is($out, "pong\n", 'module load resolves relative paths from the caller module directory');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
sub call_main()
  return(who("z"))
end
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
sub who($x)
  return(concat("main:", $x))
end
load("alpha")
print(alpha/call_main())
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'module can resolve main symbols unqualified');
    is($out, "main:z\n", 'main module remains an unqualified fallback namespace');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'alpha.slup'), <<'SLUP');
$LOAD_COUNT = add($LOAD_COUNT, 1)
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
$LOAD_COUNT = 0
load("alpha")
load("alpha")
print($LOAD_COUNT)
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'loading same module twice executes module once');
    is($out, "1\n", 'load() caches module execution by resolved path');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'a.slup'), <<'SLUP');
load("b")
SLUP
    write_text(File::Spec->catfile($dir, 'b.slup'), <<'SLUP');
load("a")
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
load("a")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'cyclic load fails');
    like($out, qr/load: cyclic dependency detected:/, 'cyclic load failure is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'left', 'alpha.slup'), <<'SLUP');
print("left")
SLUP
    write_text(File::Spec->catfile($dir, 'right', 'alpha.slup'), <<'SLUP');
print("right")
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
load("left/alpha")
load("right/alpha")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'module name collision across different files fails');
    like($out, qr/module name collision 'alpha'/, 'module name collision error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set @ARGS = ["a", "b"]
print(len(@ARGS))
print(gt(len(dict-keys(%ENV)), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'uppercase @ARGS and %ENV are globals');
    is($out, "2\n1\n", 'global arrays/dicts are accessible without namespacing');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
print(sh("echo ok"))
print(sh("echo ok | cat", 1))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sh() works for safe commands and explicit-unsafe override');
    is($out, "ok\nok\n", 'sh() output is captured for safe and overridden commands');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
sh("echo ok | cat")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'sh() rejects unsafe shell metacharacters by default');
    like($out, qr/unsafe shell metacharacters detected/, 'unsafe sh() error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
stderr("warn")
print("out")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'stderr() builtin executes');
    like($out, qr/(?:warn\nout\n|out\nwarn\n)\z/, 'stderr() emits alongside stdout with line semantics');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = run(["/bin/sh", "-c", "printf out; printf err 1>&2"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'run() captures command output');
    is($out, "0\nout\nerr\n", 'run() returns dict with code/out/err');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = run(["/bin/sh", "-c", "printf bad 1>&2; exit 7"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'run() does not crash on non-zero exit');
    is($out, "7\n\nbad\n", 'run() preserves non-zero status and stderr');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = pipe([["/bin/sh", "-c", "printf hi"], ["tr", "a-z", "A-Z"]])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'pipe() executes command pipeline');
    is($out, "0\nHI\n\n", 'pipe() returns last stdout and combined stderr');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = pipe([["/bin/sh", "-c", "printf x"], ["/bin/sh", "-c", "cat >/dev/null; printf boom 1>&2; exit 9"]])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'pipe() returns control for non-zero pipeline exits');
    is($out, "9\n\nboom\n", 'pipe() reports last command status and stderr');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = run(["/bin/sh", "-c", "sleep 2; printf late"], 0.1)
print(dict-get(%r, "code"))
print(eq(dict-get(%r, "out"), ""))
print(matchrx(dict-get(%r, "err"), #"timed out after"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'run() timeout completes without hanging interpreter');
    is($out, "124\n1\n1\n", 'run() timeout reports timeout code and error');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %r = pipe([["/bin/sh", "-c", "sleep 2; printf late"], ["cat"]], 0.1)
print(dict-get(%r, "code"))
print(eq(dict-get(%r, "out"), ""))
print(matchrx(dict-get(%r, "err"), #"timed out after"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'pipe() timeout completes without hanging interpreter');
    is($out, "124\n1\n1\n", 'pipe() timeout reports timeout code and error');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
run(["/bin/sh", "-c", "printf ok"], 0)
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'run() rejects non-positive timeout');
    like($out, qr/run: timeout must be a positive number of seconds/, 'run() timeout validation error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $src = File::Spec->catfile($dir, 'src.bin');
    my $dst = File::Spec->catfile($dir, 'dst.bin');
    open my $fh, '>:raw', $src or die "cannot write $src: $!";
    print {$fh} "\x00\xffABC\x0a";
    close $fh;
    chmod 0751, $src or die "cannot chmod $src: $!";
    my $fixed = time - 120;
    utime $fixed, $fixed, $src or die "cannot utime $src: $!";

    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
cp("$src", "$dst")
print(file->exists("$dst"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'cp() executes for binary files');
    is($out, "1\n", 'cp() creates destination file');

    is(slurp_raw($dst), slurp_raw($src), 'cp() preserves binary content');
    is((stat($dst))[2] & 07777, (stat($src))[2] & 07777, 'cp() preserves mode bits');
    is((stat($dst))[9], (stat($src))[9], 'cp() preserves mtime');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %caps = sys("sys.capabilities")
print(dict-get(%caps, "ok"))
print(gt(len(dict-get(%caps, "items")), 0))
set %pid = sys->call("posix.getpid")
print(dict-get(%pid, "ok"))
print(gt(dict-get(%pid, "pid"), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sys capabilities and sys->call alias execute');
    is($out, "1\n1\n1\n1\n", 'sys reports capabilities and getpid through alias');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'node.txt');
    my $missing = File::Spec->catfile($dir, 'missing.txt');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
text->file("abc", "$path")
set %s = sys("posix.stat", "$path")
print(dict-get(%s, "ok"))
print(dict-get(%s, "type"))
print(gt(dict-get(%s, "size"), 0))
set %a = sys("posix.access", "$path", "rw")
print(dict-get(%a, "ok"))
print(dict-get(%a, "allowed"))
set %m = sys("posix.stat", "$missing")
print(dict-get(%m, "ok"))
print(gt(dict-get(%m, "code"), 0))
set %bad = sys("posix.nope")
print(dict-get(%bad, "ok"))
print(gt(dict-get(%bad, "code"), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sys posix stat/access paths and error paths execute');
    is($out, "1\nfile\n1\n1\n1\n0\n1\n0\n1\n", 'sys returns structured ok/code for success and failures');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set %m = sys("perl.module.require", "Digest::SHA")
print(dict-get(%m, "ok"))
set %can = sys("perl.module.can", "Digest::SHA", "sha256_hex")
print(dict-get(%can, "ok"))
print(dict-get(%can, "can"))
set %h = sys("perl.call", "Digest::SHA", "sha256_hex", ["abc"])
print(dict-get(%h, "ok"))
print(eq(dict-get(%h, "result"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"))
set %obj = sys("perl.call", "Digest::SHA", "new", ["Digest::SHA", 256])
print(dict-get(%obj, "ok"))
print(gt(dict-get(%obj, "code"), 0))
set %bad = sys("perl.call", "Digest::SHA", "nope_fn", [])
print(dict-get(%bad, "ok"))
print(gt(dict-get(%bad, "code"), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sys perl module bridge executes');
    is($out, "1\n1\n1\n1\n1\n0\n1\n0\n1\n", 'sys perl bridge supports require/can/call, blocks OO returns, and reports missing function');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $node = File::Spec->catfile($dir, 'node');
    my $link = File::Spec->catfile($dir, 'node.link');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
set %mk = sys("posix.mkdir", "$node", "0750")
print(dict-get(%mk, "ok"))
set %ch = sys("posix.chmod", "$node", "0700")
print(dict-get(%ch, "ok"))
set %st = sys("posix.stat", "$node")
print(eq(dict-get(%st, "type"), "dir"))
set %ut = sys("posix.utime", "$node", 1, 2)
print(dict-get(%ut, "ok"))
set %ln = sys("posix.symlink", "$node", "$link")
print(dict-get(%ln, "ok"))
set %ls = sys("posix.lstat", "$link")
print(eq(dict-get(%ls, "type"), "link"))
set %rl = sys("posix.readlink", "$link")
print(dict-get(%rl, "ok"))
set %ul = sys("posix.unlink", "$link")
print(dict-get(%ul, "ok"))
set %rd = sys("posix.rmdir", "$node")
print(dict-get(%rd, "ok"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sys posix mutation capabilities execute');
    is($out, "1\n1\n1\n1\n1\n1\n1\n1\n1\n", 'mkdir/chmod/stat/utime/symlink/lstat/readlink/unlink/rmdir all succeed');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $lines_path = File::Spec->catfile($dir, 'lines.txt');
    my $text_path = File::Spec->catfile($dir, 'text.txt');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
set \@xs = ["alpha", "beta"]
lines->file(\@xs, "$lines_path")
set \@ys = file->lines("$lines_path")
print(len(\@ys))
print(get(\@ys, 0))
text->file("hello", "$text_path")
print(file->text("$text_path"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'directional file aliases execute');
    is($out, "2\nalpha\nhello\n", 'file->text/text->file and file->lines/lines->file roundtrip correctly');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $subdir = File::Spec->catfile($dir, 'subdir');
    my $text_path = File::Spec->catfile($dir, 'aliases.txt');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
mkdir("$subdir")
set \@xs = ["a", "b"]
array->push(\@xs, "c")
print(array->len(\@xs))
print(array->get(\@xs, 2))
print(array->pop(\@xs))
set %d = {k: "v"}
print(dict->get(%d, "k"))
dict->set(%d, "k", "z")
print(dict->has(%d, "k"))
print(dict->get(%d, "k"))
print(text->len("abc"))
print(text->upper("ab"))
print(text->lower("XY"))
print(dir->exists("$subdir"))
text->file("x", "$text_path")
print(file->exists("$text_path"))
print(gt(text->len(dir->cwd()), 0))
set \$jp = path->join("$subdir", "joined.txt")
text->file("A", \$jp)
file->append("B", \$jp)
print(file->text(\$jp))
file->remove(\$jp)
print(file->exists(\$jp))
dir->chdir("$subdir")
print(dir->exists(".."))
set \@entries = dir->entries("$dir")
print(gt(array->len(\@entries), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'namespaced aliases execute');
    is($out, "3\nc\nc\nv\n1\nz\n3\nAB\nxy\n1\n1\n1\nAB\n0\n1\n1\n", 'array/dict/text/dir/file aliases preserve behavior');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $subdir = File::Spec->catfile($dir, 'nested');
    my $file = File::Spec->catfile($subdir, 'demo.txt');
    mkdir $subdir or die "cannot mkdir $subdir: $!";
    write_text($file, "hello");
    my $missing = File::Spec->catfile($dir, 'missing.file');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
set \@entries = dir->list("$subdir")
print(gt(len(\@entries), 0))
print(path->basename("$file"))
print(path->dirname("$file"))
print(path->type("$file"))
print(path->is-file("$file"))
print(path->type("$subdir"))
print(path->is-dir("$subdir"))
print(path->type("$missing"))
print(matchrx(date->today(), #"^[0-9]{4}-[0-9]{2}-[0-9]{2}\$"))
print(gt(time->now(), 0))
print(matchrx(time->iso-utc(), #"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$"))
print(matchrx(date(), #"^[0-9]{4}-[0-9]{2}-[0-9]{2}\$"))
print(gt(time(), 0))
print(matchrx(time-iso(), #"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'shell-first path and date/time builtins execute');
    is($out, "1\ndemo.txt\n$subdir\nfile\n1\ndir\n1\nmissing\n1\n1\n1\n1\n1\n1\n", 'path checks, basename/dirname, and date/time helpers behave as expected');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $marker = File::Spec->catfile($dir, 'marker.txt');
    write_text($marker, "ok");
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
print(true())
print(false())
set \$p = pwd()
print(gt(text->len(\$p), 0))
cd("$dir")
print(file->exists("marker.txt"))
set \$old = umask()
set \$prev = umask("077")
print(gt(\$old, -1))
print(eq(\$prev, \$old))
set \$restore = umask(\$old)
print(gt(\$restore, -1))
set \@t = times()
print(eq(len(\@t), 4))
set %me = sys("posix.getpid")
print(gt(kill(0, dict-get(%me, "pid")), 0))
set %w = wait(-1)
print(eq(dict-get(%w, "pid"), -1))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'shell-style builtins execute');
    is($out, "1\n0\n1\n1\n1\n1\n1\n1\n1\n1\n", 'true/false/pwd/cd/umask/times/kill/wait behave as expected');
}

SKIP: {
    my $dir = tempdir(CLEANUP => 1);
    my $sock_path = File::Spec->catfile($dir, 'daemon.sock');
    my $sock = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Local => $sock_path,
        Listen => 1,
    );
    skip 'unix domain sockets unavailable on this platform', 2 unless $sock;
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
print(path->type("$sock_path"))
print(path->is-socket("$sock_path"))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'path socket checks execute');
    is($out, "socket\n1\n", 'path->type/path->is-socket detect unix sockets');
    close $sock;
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set $user-name = "ben"
set $http->status = "200"
set $ready? = "yes"
$MY-GLOBAL? = "OK"
print($user-name)
print($http->status)
print($ready?)
print($MY-GLOBAL?)
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'dash, arrow, and question-mark symbols execute');
    is($out, "ben\n200\nyes\nOK\n", 'symbol names support -, ->, and ?');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set $Bad = "x"
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'mixed-case local variable names are rejected');
    like($out, qr/locals must be lowercase/, 'mixed-case local rejection is clear');
}

done_testing();
