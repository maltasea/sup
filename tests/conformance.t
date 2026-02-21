#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Spec;

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
