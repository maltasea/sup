#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 147;
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

sub run_slup_env {
    my ($env, $program) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.slup', UNLINK => 1);
    print {$fh} $program;
    close $fh;

    local %ENV = %ENV;
    for my $k (keys %{$env}) {
        $ENV{$k} = $env->{$k};
    }
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

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $bytes;
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
def $base = 5
let $next = add($base, 1)
defun bump($x)
  return(add($x, 1))
end
print($next)
print(bump(9))
SLUP
    is($status, 0, 'def/let/defun aliases execute (ocaml)');
    is($out, "6\n10\n", 'def/let/defun aliases output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @xs = [1, 2, 3]
set @ys = map(@xs, fun($x -> add($x, 1)))
print(get(@ys, 0))
print(get(@ys, 2))
SLUP
    is($status, 0, 'fun(...) lambda form executes (ocaml)');
    is($out, "2\n4\n", 'fun(...) lambda form output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
defn bump($x)
  return(add($x, 1))
end
set @xs = [9]
set @ys = map(@xs, fn($x -> bump($x)))
print(get(@ys, 0))
SLUP
    is($status, 0, 'defn/fn compatibility aliases execute (ocaml)');
    is($out, "10\n", 'defn/fn compatibility aliases output (ocaml)');
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
when eq("a", "a")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'when executes then-branch when condition is true (ocaml)');
    is($out, "x\n", 'when true condition output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
when eq("a", "b")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'when executes else-branch when condition is false (ocaml)');
    is($out, "y\n", 'when false condition output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "b")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'unless executes then-branch when condition is false (ocaml)');
    is($out, "x\n", 'unless false condition output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "a")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'unless executes else-branch when condition is true (ocaml)');
    is($out, "y\n", 'unless true condition output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $x = 0
while lt($x, 3)
  set $x = add($x, 1)
end
print($x)
SLUP
    is($status, 0, 'while executes until condition becomes false (ocaml)');
    is($out, "3\n", 'while re-evaluates condition per iteration (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $x = 7
while lt($x, 3)
  set $x = 0
end
print($x)
SLUP
    is($status, 0, 'while allows zero-iteration execution (ocaml)');
    is($out, "7\n", 'while skips body when condition starts false (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
switch "b"
case "a"
  print("A")
case "b"
  print("B")
case "b"
  print("B2")
else
  print("E")
end
SLUP
    is($status, 0, 'switch/case executes with matching branch (ocaml)');
    is($out, "B\n", 'switch runs first matching case only (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
switch "z"
case "a"
  print("A")
case "b"
  print("B")
else
  print("E")
end
SLUP
    is($status, 0, 'switch executes else when no case matches (ocaml)');
    is($out, "E\n", 'switch else branch output (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
case "x"
  print("x")
end
SLUP
    ok($status != 0, 'case outside switch fails (ocaml)');
    like($out, qr/case without matching switch/, 'case outside switch has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
switch "x"
case "x"
  print("x")
SLUP
    ok($status != 0, 'missing end in switch fails (ocaml)');
    like($out, qr/switch without matching end/, 'missing switch end has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @xs = ["a", "b", "c"]
fori $v @xs
  print(concat($i, $v))
end
SLUP
    is($status, 0, 'fori executes indexed iteration (ocaml)');
    is($out, "0a\n1b\n2c\n", 'fori exposes $i index each iteration (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @xs = ["a", "b"]
fori $v @xs
  print($v)
  push(@xs, "z")
end
print(len(@xs))
SLUP
    is($status, 0, 'fori executes with array mutation in loop body (ocaml)');
    is($out, "a\nb\n4\n", 'fori iterates over snapshot while body can mutate source array (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @x = [1, 2]
fori $v @x
  print($v)
SLUP
    ok($status != 0, 'missing end in fori fails (ocaml)');
    like($out, qr/fori without matching end/, 'missing fori end has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub count-down($n)
  if lt($n, 1)
    return(0)
  end
  return(add(1, count-down(sub($n, 1))))
end
print(count-down(3))
SLUP
    ok($status != 0, 'sub recursion is rejected by default (ocaml)');
    like($out, qr/recursion is not allowed for sub 'count-down'/, 'sub recursion error explains rec requirement (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
rec count-down($n)
  if lt($n, 1)
    return(0)
  end
  return(add(1, count-down(sub($n, 1))))
end
print(count-down(3))
SLUP
    is($status, 0, 'rec allows direct recursion (ocaml)');
    is($out, "3\n", 'rec direct recursion computes expected result (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub a($n)
  if lt($n, 1)
    return(0)
  end
  return(b(sub($n, 1)))
end
sub b($n)
  if lt($n, 1)
    return(0)
  end
  return(a(sub($n, 1)))
end
print(a(2))
SLUP
    ok($status != 0, 'mutual recursion is rejected for non-rec functions (ocaml)');
    like($out, qr/recursion is not allowed for sub 'a'/, 'mutual recursion error points at recursive target (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
rec a($n)
  if lt($n, 1)
    return(0)
  end
  return(b(sub($n, 1)))
end
rec b($n)
  if lt($n, 1)
    return(0)
  end
  return(a(sub($n, 1)))
end
print(a(2))
SLUP
    is($status, 0, 'mutual recursion is allowed for rec functions (ocaml)');
    is($out, "0\n", 'mutual rec recursion can terminate via base case (ocaml)');
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
print("ok")
missing()
SLUP
    ok($status != 0, 'unknown call fails with line context (ocaml)');
    like($out, qr/line 2: Unknown function: missing/, 'unknown call reports line-prefixed error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
print("ok")
read-file("")
SLUP
    ok($status != 0, 'builtin runtime error fails with line context (ocaml)');
    like($out, qr/line 2: read-file: missing filename/, 'builtin runtime error reports line-prefixed error (ocaml)');
}

{
    my ($status, $out) = run_slup_env({ SLUP_MAX_CALL_DEPTH => 6 }, <<'SLUP');
rec dive($n)
  if lt($n, 1)
    return(0)
  end
  return(dive(sub($n, 1)))
end
print(dive(20))
SLUP
    ok($status != 0, 'configurable max call depth rejects overly deep recursion (ocaml)');
    like($out, qr/maximum call depth exceeded/, 'call depth hardening error is clear (ocaml)');
}

{
    my ($status, $out) = run_slup_env({ SLUP_MAX_CAPTURE_BYTES => 8 }, <<'SLUP');
set %r = run(["/bin/sh", "-c", "printf 1234567890"])
print(dict-get(%r, "out"))
SLUP
    ok($status != 0, 'run() fails when captured output exceeds configured cap (ocaml)');
    like($out, qr/captured output exceeds/, 'captured-output hardening error is clear (ocaml)');
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
when eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in when fails (ocaml)');
    like($out, qr/when without matching end/, 'missing when end has clear error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in unless fails (ocaml)');
    like($out, qr/unless without matching end/, 'missing unless end has clear error (ocaml)');
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
    is($status, 0, 'loading same module twice executes module once (ocaml)');
    is($out, "1\n", 'load() caches module execution by resolved path (ocaml)');
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
    ok($status != 0, 'cyclic load fails (ocaml)');
    like($out, qr/load: cyclic dependency detected:/, 'cyclic load failure is clear (ocaml)');
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
    ok($status != 0, 'module name collision across different files fails (ocaml)');
    like($out, qr/module name collision 'alpha'/, 'module name collision error is clear (ocaml)');
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
print(sh("echo ok"))
print(sh("echo ok | cat", 1))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'sh() works for safe commands and explicit-unsafe override (ocaml)');
    is($out, "ok\nok\n", 'sh() output is captured for safe and overridden commands (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
sh("echo ok | cat")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    ok($status != 0, 'sh() rejects unsafe shell metacharacters by default (ocaml)');
    like($out, qr/unsafe shell metacharacters detected/, 'unsafe sh() error is clear (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.slup'), <<'SLUP');
stderr("warn")
print("out")
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'stderr() builtin executes (ocaml)');
    like($out, qr/(?:warn\nout\n|out\nwarn\n)\z/, 'stderr() emits alongside stdout with line semantics (ocaml)');
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
    my ($status, $out) = run_slup(<<'SLUP');
set %r = run(["/bin/sh", "-c", "sleep 2; printf late"], 0.1)
print(dict-get(%r, "code"))
print(eq(dict-get(%r, "out"), ""))
print(matchrx(dict-get(%r, "err"), #"timed out after"))
SLUP
    is($status, 0, 'run() timeout completes without hanging interpreter (ocaml)');
    is($out, "124\n1\n1\n", 'run() timeout reports timeout code and error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %r = pipe([["/bin/sh", "-c", "sleep 2; printf late"], ["cat"]], 0.1)
print(dict-get(%r, "code"))
print(eq(dict-get(%r, "out"), ""))
print(matchrx(dict-get(%r, "err"), #"timed out after"))
SLUP
    is($status, 0, 'pipe() timeout completes without hanging interpreter (ocaml)');
    is($out, "124\n1\n1\n", 'pipe() timeout reports timeout code and error (ocaml)');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
run(["/bin/sh", "-c", "printf ok"], 0)
SLUP
    ok($status != 0, 'run() rejects non-positive timeout (ocaml)');
    like($out, qr/run: timeout must be a positive number of seconds/, 'run() timeout validation error is clear (ocaml)');
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
    is($status, 0, 'cp() executes for binary files (ocaml)');
    is($out, "1\n", 'cp() creates destination file (ocaml)');
    is(slurp_raw($dst), slurp_raw($src), 'cp() preserves binary content (ocaml)');
    is((stat($dst))[2] & 07777, (stat($src))[2] & 07777, 'cp() preserves mode bits (ocaml)');
    is((stat($dst))[9], (stat($src))[9], 'cp() preserves mtime (ocaml)');
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
    is($status, 0, 'sys capabilities and sys->call alias execute (ocaml)');
    is($out, "1\n1\n1\n1\n", 'sys reports capabilities and getpid through alias (ocaml)');
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
    is($status, 0, 'sys posix stat/access paths and error paths execute (ocaml)');
    is($out, "1\nfile\n1\n1\n1\n0\n1\n0\n1\n", 'sys returns structured ok/code for success and failures (ocaml)');
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
    is($status, 0, 'sys posix mutation capabilities execute (ocaml)');
    is($out, "1\n1\n1\n1\n1\n1\n1\n1\n1\n", 'mkdir/chmod/stat/utime/symlink/lstat/readlink/unlink/rmdir all succeed (ocaml)');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'node.txt');
    write_text(File::Spec->catfile($dir, 'main.slup'), <<"SLUP");
text->file("x", "$path")
print(eq(path->basename("$path"), "node.txt"))
print(eq(path->dirname("$path"), "$dir"))
print(eq(path->type("$path"), "file"))
print(path->is-file("$path"))
print(path->is-dir("$dir"))
print(eq(path->type("$dir"), "dir"))
print(gt(text->len(date->today()), 0))
print(gt(time->now(), 0))
print(matchrx(time->iso-utc(), #"T"))
print(gt(len(dir->list("$dir")), 0))
SLUP
    my ($status, $out) = run_file(File::Spec->catfile($dir, 'main.slup'));
    is($status, 0, 'path/date/time aliases execute (ocaml)');
    is($out, "1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n", 'path/date/time and dir->list aliases preserve behavior (ocaml)');
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
    is($status, 0, 'directional file aliases execute (ocaml)');
    is($out, "2\nalpha\nhello\n", 'file->text/text->file and file->lines/lines->file roundtrip correctly (ocaml)');
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
    is($status, 0, 'namespaced aliases execute (ocaml)');
    is($out, "3\nc\nc\nv\n1\nz\n3\nAB\nxy\n1\n1\n1\nAB\n0\n1\n1\n", 'array/dict/text/dir/file aliases preserve behavior (ocaml)');
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
