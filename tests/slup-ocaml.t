#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 60;
use File::Path qw(make_path);
use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use File::Spec;

my $root = File::Spec->catdir($Bin, '..');
my $demo = File::Spec->catfile($root, 'demo.slup');

my $build_cmd = qq{cd "$root" && eval \$(opam env) && dune build ./slup.exe 2>&1};
my $build_out = `$build_cmd`;
my $build_status = $? >> 8;
if ($build_status != 0) {
    BAIL_OUT("dune build failed:\n$build_out");
}

my $slup = File::Spec->catfile($root, '_build', 'default', 'slup.exe');

sub run_slup {
    my ($program) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.slup', UNLINK => 1);
    print {$fh} $program;
    close $fh;

    my $cmd = qq{"$slup" "$path" < /dev/null 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub run_file {
    my ($path) = @_;
    my $cmd = qq{"$slup" "$path" < /dev/null 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub run_file_with_opt {
    my ($opt, $path) = @_;
    my $cmd = qq{"$slup" $opt "$path" < /dev/null 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub write_text {
    my ($path, $content) = @_;
    my ($vol, $dir, undef) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $sum = add(2, 3)
print($sum)
SLUP
    is($status, 0, 'basic arithmetic exits successfully (ocaml)');
    is($out, "5\n", 'basic arithmetic output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub double($n)
  return(mul($n, 2))
  print("dead code")
end
print(double(4))
SLUP
    is($status, 0, 'return(...) in sub exits successfully (ocaml)');
    is($out, "8\n", 'return(...) exits sub body early (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub find-blue()
  set @colors = ["red", "blue", "green"]
  foreach $c @colors
    if eq($c, "blue")
      return($c)
    end
  end
  return("none")
end
print(find-blue())
SLUP
    is($status, 0, 'return(...) propagates through nested blocks (ocaml)');
    is($out, "blue\n", 'nested return value is preserved (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
return("x")
SLUP
    ok($status != 0, 'return(...) outside sub fails (ocaml)');
    like($out, qr/return outside sub/, 'outside-sub return has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $who = "Ben"
print("line1\nline2")
print("quote: \" slash: \\ literal: \$who interp: $who")
SLUP
    my $expected = "line1\nline2\nquote: \" slash: \\ literal: \$who interp: Ben\n";
    is($status, 0, 'escaped strings execute (ocaml)');
    is($out, $expected, 'string escapes and interpolation work (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %d = {"api-key": "x", "space key": "y", plain: "z"}
print(dict-get(%d, "api-key"))
print(dict-get(%d, "space key"))
print(dict-get(%d, "plain"))
SLUP
    is($status, 0, 'quoted dict keys execute (ocaml)');
    is($out, "x\ny\nz\n", 'quoted and bare dict keys can coexist (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $k = "dyn"
set %d = {$k: 7}
print(dict-get(%d, "dyn"))
SLUP
    is($status, 0, 'dict key expression executes (ocaml)');
    is($out, "7\n", 'dict key expression resolves (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
print(concat("a\",b", "X"))
SLUP
    is($status, 0, 'escaped quote in arg list executes (ocaml)');
    is($out, "a\",bX\n", 'escaped quote keeps comma inside argument (ocaml)');
}

{
    my $count = 2000;
    my $ones = join(',', (1) x $count);
    my $program = <<"SLUP";
set \@seed = [$ones]
set \@xs = []
foreach \$n \@seed
  push(\@xs, \$n)
end
print(len(\@xs))
print(get(\@xs, 1999))
print(pop(\@xs))
print(len(\@xs))
SLUP
    my ($status, $out) = run_slup($program);
    is($status, 0, 'large push loop executes (ocaml)');
    is($out, "2000\n1\n1\n1999\n", 'push/get/pop/len stay consistent under load (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
if eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in if fails (ocaml)');
    like($out, qr/if without matching end/, 'missing if end has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub bad($x)
  print($x)
SLUP
    ok($status != 0, 'missing end in sub fails (ocaml)');
    like($out, qr/sub without matching end/, 'missing sub end has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @x = [1, 2]
foreach $v @x
  print($v)
SLUP
    ok($status != 0, 'missing end in foreach fails (ocaml)');
    like($out, qr/foreach without matching end/, 'missing foreach end has clear error (ocaml)');
}

{
    my ($status, $out) = run_file($demo);
    is($status, 0, 'demo.slup executes (ocaml)');
    like($out, qr/-- demo complete --\n/, 'demo.slup reaches completion (ocaml)');
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
    is($status, 0, 'qualified and unqualified function calls execute (ocaml)');
    is($out, "main:A\nalpha:B\n", 'main stays unqualified, module requires qualification (ocaml)');
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
    ok($status != 0, 'module-only function is not available unqualified (ocaml)');
    like($out, qr/Unknown function: only_alpha/, 'unqualified module-only function fails clearly (ocaml)');
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
    is($status, 0, 'global variables are shared across modules (ocaml)');
    is($out, "from-module\nfrom-module\n", 'global value is shared and visible in both main and module (ocaml)');
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
    is($status, 0, 'qualified var/array/dict access executes (ocaml)');
    is($out, "main-local\nmodule-local\n3\nv\n", 'module symbols stay scoped and are reachable through module/name (ocaml)');
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
    is($status, 0, 'relative load from inside a module executes (ocaml)');
    is($out, "pong\n", 'module load resolves relative paths from caller module directory (ocaml)');
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
    is($status, 0, 'module can resolve main symbols unqualified (ocaml)');
    is($out, "main:z\n", 'main module remains an unqualified fallback namespace (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set @ARGS = ["a", "b"]
print(len(@ARGS))
print(gt(len(dict-keys(%ENV)), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'uppercase @ARGS and %ENV are globals (ocaml)');
    is($out, "2\n1\n", 'global arrays/dicts are accessible without namespacing (ocaml)');
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
    is($status, 0, 'dash, arrow, and question-mark symbols execute (ocaml)');
    is($out, "ben\n200\nyes\nOK\n", 'symbol names support -, ->, and ? (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
set $Bad = "x"
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'mixed-case local variable names are rejected (ocaml)');
    like($out, qr/locals must be lowercase/, 'mixed-case local rejection is clear (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %r = run(["/bin/sh", "-c", "printf out; printf err 1>&2"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    is($status, 0, 'run() captures command output (ocaml)');
    is($out, "0\nout\nerr\n", 'run() returns dict with code/out/err (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %r = run(["/bin/sh", "-c", "printf bad 1>&2; exit 7"])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    is($status, 0, 'run() does not crash on non-zero exit (ocaml)');
    is($out, "7\n\nbad\n", 'run() preserves non-zero status and stderr (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %r = pipe([["/bin/sh", "-c", "printf hi"], ["tr", "a-z", "A-Z"]])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    is($status, 0, 'pipe() executes command pipeline (ocaml)');
    is($out, "0\nHI\n\n", 'pipe() returns last stdout and combined stderr (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %r = pipe([["/bin/sh", "-c", "printf x"], ["/bin/sh", "-c", "cat >/dev/null; printf boom 1>&2; exit 9"]])
print(dict-get(%r, "code"))
print(dict-get(%r, "out"))
print(dict-get(%r, "err"))
SLUP
    is($status, 0, 'pipe() returns control for non-zero pipeline exits (ocaml)');
    is($out, "9\n\nboom\n", 'pipe() reports last command status and stderr (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'mod.slup'), <<'SLUP');
$DB_HOST = "localhost"
SLUP
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
global $DB_HOST required
load("mod")
SLUP
    my ($status, $out) = run_file_with_opt('--check', File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, '--check passes when required global is assigned (ocaml)');
    is($out, '', '--check success is silent (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
global $DB_HOST required
set $path = "mod"
load($path)
SLUP
    my ($status, $out) = run_file_with_opt('--check', File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, '--check rejects dynamic load targets (ocaml)');
    like($out, qr/static check requires load\("literal"\)/, '--check reports dynamic load limitation (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
global $DB_PORT default("5432")
print($DB_PORT)
SLUP
    my ($status, $out) = run_file_with_opt('--strict-globals', File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'strict mode applies declared defaults (ocaml)');
    is($out, "5432\n", 'strict mode exposes defaulted globals (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
global $DECLARED default("ok")
print($MISSING)
SLUP
    my ($status, $out) = run_file_with_opt('--strict-globals', File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'strict mode rejects undeclared global reads (ocaml)');
    like($out, qr/undeclared global read/, 'strict mode undeclared-read error is clear (ocaml)');
}
