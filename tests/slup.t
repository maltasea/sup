#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 56;
use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use File::Spec;

my $slup = File::Spec->catfile($Bin, '..', 'slup.pl');
my $demo = File::Spec->catfile($Bin, '..', 'demo.slup');

sub run_slup {
    my ($program) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.slup', UNLINK => 1);
    print {$fh} $program;
    close $fh;

    my $cmd = qq{perl "$slup" "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub run_file {
    my ($path) = @_;
    my $cmd = qq{perl "$slup" "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $sum = add(2, 3)
print($sum)
SLUP
    is($status, 0, 'basic arithmetic exits successfully');
    is($out, "5\n", 'basic arithmetic output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
def $base = 5
let $next = add($base, 1)
defn bump($x)
  return(add($x, 1))
end
print($next)
print(bump(9))
SLUP
    is($status, 0, 'def/let/defn aliases execute');
    is($out, "6\n10\n", 'def/let/defn aliases output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @xs = [1, 2, 3, 4]
set @ys = map(@xs, fn($x -> add($x, 1)))
set @zs = map(@xs, {$x -> add($x, 10)})
set @big = filter(@ys, fn($x -> gt($x, 2)))
set @small = grep(@ys, fn($x -> lt($x, 4)))
print(get(@ys, 0))
print(get(@zs, 3))
print(len(@big))
print(len(@small))
SLUP
    is($status, 0, 'fn/lambda with map/filter/grep executes');
    is($out, "2\n14\n3\n2\n", 'fn/lambda map/filter/grep output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub double($n)
  return(mul($n, 2))
  print("dead code")
end
print(double(4))
SLUP
    is($status, 0, 'return(...) in sub exits successfully');
    is($out, "8\n", 'return(...) exits sub body early');
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
    is($status, 0, 'return(...) propagates through nested blocks');
    is($out, "blue\n", 'nested return value is preserved');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
when eq("a", "a")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'when executes then-branch when condition is true');
    is($out, "x\n", 'when true condition output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
when eq("a", "b")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'when executes else-branch when condition is false');
    is($out, "y\n", 'when false condition output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "b")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'unless executes then-branch when condition is false');
    is($out, "x\n", 'unless false condition output');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "a")
  print("x")
else
  print("y")
end
SLUP
    is($status, 0, 'unless executes else-branch when condition is true');
    is($out, "y\n", 'unless true condition output');
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
    ok($status != 0, 'sub recursion is rejected by default');
    like($out, qr/recursion is not allowed for sub 'count-down'/, 'sub recursion error explains rec requirement');
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
    is($status, 0, 'rec allows direct recursion');
    is($out, "3\n", 'rec direct recursion computes expected result');
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
    ok($status != 0, 'mutual recursion is rejected for non-rec functions');
    like($out, qr/recursion is not allowed for sub 'a'/, 'mutual recursion error points at recursive target');
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
    is($status, 0, 'mutual recursion is allowed for rec functions');
    is($out, "0\n", 'mutual rec recursion can terminate via base case');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
return("x")
SLUP
    ok($status != 0, 'return(...) outside sub fails');
    like($out, qr/return outside sub/, 'outside-sub return has clear error');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $who = "Ben"
print("line1\nline2")
print("quote: \" slash: \\ literal: \$who interp: $who")
SLUP
    my $expected = "line1\nline2\nquote: \" slash: \\ literal: \$who interp: Ben\n";
    is($status, 0, 'escaped strings execute');
    is($out, $expected, 'string escapes and interpolation work');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set %d = {"api-key": "x", "space key": "y", plain: "z"}
print(dict-get(%d, "api-key"))
print(dict-get(%d, "space key"))
print(dict-get(%d, "plain"))
SLUP
    is($status, 0, 'quoted dict keys execute');
    is($out, "x\ny\nz\n", 'quoted and bare dict keys can coexist');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set $k = "dyn"
set %d = {$k: 7}
print(dict-get(%d, "dyn"))
SLUP
    is($status, 0, 'dict key expression executes');
    is($out, "7\n", 'dict key expression resolves');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
print(concat("a\",b", "X"))
SLUP
    is($status, 0, 'escaped quote in arg list executes');
    is($out, "a\",bX\n", 'escaped quote keeps comma inside argument');
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
    is($status, 0, 'large push loop executes');
    is($out, "2000\n1\n1\n1999\n", 'push/get/pop/len stay consistent under load');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
$MYGLOBAL = "E3E"
sub show()
  print($MYGLOBAL)
  $MYGLOBAL = "UPDATED"
end
show()
print($MYGLOBAL)
SLUP
    is($status, 0, 'global assignment syntax executes');
    is($out, "E3E\nUPDATED\n", 'global vars are visible and mutable across subs');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $mod = File::Spec->catfile($dir, 'moda.slup');
    my $main = File::Spec->catfile($dir, 'main.slup');

    open my $mfh, '>', $mod or die "cannot write $mod: $!";
    print {$mfh} <<'SLUP';
set $m = "mod"
sub who($x)
  return(concat(concat($m, ":"), $x))
end
$SHARED = "module"
SLUP
    close $mfh;

    open my $fh, '>', $main or die "cannot write $main: $!";
    print {$fh} <<'SLUP';
set $m = "main"
sub who($x)
  return(concat(concat($m, ":"), $x))
end
$SHARED = "main"
load("moda")
print(who("A"))
print(moda/who("B"))
print($SHARED)
print($moda/m)
SLUP
    close $fh;

    my ($status, $out) = run_file($main);
    is($status, 0, 'module scoping and qualified symbol lookup execute');
    is($out, "main:A\nmod:B\nmodule\nmod\n", 'main symbols stay unqualified, module symbols are qualified, globals are shared');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $mod = File::Spec->catfile($dir, 'modb.slup');
    my $main = File::Spec->catfile($dir, 'main.slup');

    open my $mfh, '>', $mod or die "cannot write $mod: $!";
    print {$mfh} <<'SLUP';
sub only_mod()
  return("x")
end
SLUP
    close $mfh;

    open my $fh, '>', $main or die "cannot write $main: $!";
    print {$fh} <<'SLUP';
load("modb")
print(only_mod())
SLUP
    close $fh;

    my ($status, $out) = run_file($main);
    ok($status != 0, 'module-local functions are not visible unqualified');
    like($out, qr/Unknown function: only_mod/, 'unqualified lookup fails for module-local function');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
if eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in if fails');
    like($out, qr/if without matching end/, 'missing if end has clear error');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
when eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in when fails');
    like($out, qr/when without matching end/, 'missing when end has clear error');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
unless eq("a", "a")
  print("x")
SLUP
    ok($status != 0, 'missing end in unless fails');
    like($out, qr/unless without matching end/, 'missing unless end has clear error');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
sub bad($x)
  print($x)
SLUP
    ok($status != 0, 'missing end in sub fails');
    like($out, qr/sub without matching end/, 'missing sub end has clear error');
}

{
    my ($status, $out) = run_slup(<<'SLUP');
set @x = [1, 2]
foreach $v @x
  print($v)
SLUP
    ok($status != 0, 'missing end in foreach fails');
    like($out, qr/foreach without matching end/, 'missing foreach end has clear error');
}

{
    my ($status, $out) = run_file($demo);
    is($status, 0, 'demo.slup executes');
    like($out, qr/-- demo complete --\n/, 'demo.slup reaches completion');
}
