#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 96;
use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use File::Spec;

my $sup = File::Spec->catfile($Bin, '..', 'sup.pl');
my $demo = File::Spec->catfile($Bin, '..', 'demo.sup');

my $sup_cmd = $ENV{SUP_CMD}
    ? $ENV{SUP_CMD}
    : qq{perl "$sup"};

sub run_sup {
    my ($program) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.sup', UNLINK => 1);
    print {$fh} $program;
    close $fh;

    my $cmd = qq{$sup_cmd "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

sub run_file {
    my ($path) = @_;
    my $cmd = qq{$sup_cmd "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

{
    my ($status, $out) = run_sup(<<'SUP');
set $sum = add(2, 3)
print($sum)
SUP
    is($status, 0, 'basic arithmetic exits successfully');
    is($out, "5\n", 'basic arithmetic output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
def base = 2
let bump = 3
defun plus [a, b] do
  return a + b
end
total = plus(base, bump)
if total == 5 then
  print("ok")
elif total == 6 then
  print("bad")
else
  print("no")
end
let xs = [1, 2, 3]
let acc = 0
foreach x in xs do
  acc = acc + x
end
print(acc)
let i = 0
let w = 0
while i < 5 do
  i = i + 1
  if i == 2 then
    continue
  end
  if i == 4 then
    break
  end
  w = w + i
end
print(w)
let d = {name: "bernd", age: 88}
print(d["name"])
d["age"] = 89
print(d["age"])
SUP
    is($status, 0, 'Mini Shelm Light statements execute');
    is($out, "ok\n6\n4\nbernd\n89\n", 'Mini Shelm Light statement semantics');
}

{
    my ($status, $out) = run_sup(<<'SUP');
let s = "bananas"
let hit = s =~ /na/
let miss = s !~ /zz/
let t = s =~ s/na/NA/g
print(hit)
print(miss)
print(t)
SUP
    is($status, 0, 'light regex forms execute');
    is($out, "1\n1\nbaNANAs\n", 'light regex operators and substitution');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set $s = "bananas"
print(replace($s, #"na", "NA"))
print(replace-all($s, #"na", "NA"))
print(text->replace-all($s, #"na", "XO"))
SUP
    is($status, 0, 'replace and replace-all helpers execute');
    is($out, "baNAnas\nbaNANAs\nbaXOXOs\n", 'replace helpers perform single/global substitution');
}

{
    my ($status, $out) = run_sup(<<'SUP');
let n = 3
print add(n, 2)
SUP
    is($status, 0, 'light bare-call statement form executes');
    is($out, "5\n", 'light bare-call statement lowers to regular call');
}

{
    my ($status, $out) = run_sup(<<'SUP');
def $base = 5
let $next = add($base, 1)
defun bump($x)
  return(add($x, 1))
end
print($next)
print(bump(9))
SUP
    is($status, 0, 'def/let/defun aliases execute');
    is($out, "6\n10\n", 'def/let/defun aliases output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defn nope($x)
  return($x)
end
SUP
    ok($status != 0, 'defn keyword is rejected');
    like($out, qr/Syntax error/, 'defn rejection is explicit');
}

{
    my ($status, $out) = run_sup(<<'SUP');
sub nope($x)
  return($x)
end
SUP
    ok($status != 0, 'sub keyword is rejected');
    like($out, qr/Syntax error/, 'sub rejection is explicit');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set @xs = [1, 2]
set @ys = map(@xs, fn($x -> add($x, 1)))
print(len(@ys))
SUP
    ok($status != 0, 'fn keyword is rejected');
    like($out, qr/Cannot evaluate expression/, 'fn rejection is explicit');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set @xs = [1, 2, 3, 4]
set @ys = map(@xs, fun($x -> add($x, 1)))
set @zs = map(@xs, {$x -> add($x, 10)})
set @big = filter(@ys, fun($x -> gt($x, 2)))
set @small = grep(@ys, fun($x -> lt($x, 4)))
print(get(@ys, 0))
print(get(@zs, 3))
print(len(@big))
print(len(@small))
SUP
    is($status, 0, 'fun/lambda with map/filter/grep executes');
    is($out, "2\n14\n3\n2\n", 'fun/lambda map/filter/grep output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
let inc = fun [x] do
  return x + 1
end
let xs = [1, 2, 3]
let ys = map(xs, inc)
print(ys[0])
print(ys[2])
print(inc(7))
SUP
    is($status, 0, 'fun [params] do ... end can produce lambda values');
    is($out, "2\n4\n8\n", 'fun block lambda works with map, indexing, and direct calls');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun double($n)
  return(mul($n, 2))
  print("dead code")
end
print(double(4))
SUP
    is($status, 0, 'return(...) in defun exits successfully');
    is($out, "8\n", 'return(...) exits defun body early');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun find-blue()
  set @colors = ["red", "blue", "green"]
  foreach $c @colors
    if eq($c, "blue")
      return($c)
    end
  end
  return("none")
end
print(find-blue())
SUP
    is($status, 0, 'return(...) propagates through nested blocks');
    is($out, "blue\n", 'nested return value is preserved');
}

{
    my ($status, $out) = run_sup(<<'SUP');
when eq("a", "a")
  print("x")
else
  print("y")
end
SUP
    is($status, 0, 'when executes then-branch when condition is true');
    is($out, "x\n", 'when true condition output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
when eq("a", "b")
  print("x")
else
  print("y")
end
SUP
    is($status, 0, 'when executes else-branch when condition is false');
    is($out, "y\n", 'when false condition output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
unless eq("a", "b")
  print("x")
else
  print("y")
end
SUP
    is($status, 0, 'unless executes then-branch when condition is false');
    is($out, "x\n", 'unless false condition output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
unless eq("a", "a")
  print("x")
else
  print("y")
end
SUP
    is($status, 0, 'unless executes else-branch when condition is true');
    is($out, "y\n", 'unless true condition output');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun count-down($n)
  if lt($n, 1)
    return(0)
  end
  return(add(1, count-down(sub($n, 1))))
end
print(count-down(3))
SUP
    ok($status != 0, 'function recursion is rejected by default');
    like($out, qr/recursion is not allowed for function 'count-down'/, 'non-rec function recursion error explains rec requirement');
}

{
    my ($status, $out) = run_sup(<<'SUP');
rec count-down($n)
  if lt($n, 1)
    return(0)
  end
  return(add(1, count-down(sub($n, 1))))
end
print(count-down(3))
SUP
    is($status, 0, 'rec allows direct recursion');
    is($out, "3\n", 'rec direct recursion computes expected result');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun a($n)
  if lt($n, 1)
    return(0)
  end
  return(b(sub($n, 1)))
end
defun b($n)
  if lt($n, 1)
    return(0)
  end
  return(a(sub($n, 1)))
end
print(a(2))
SUP
    ok($status != 0, 'mutual recursion is rejected for non-rec functions');
    like($out, qr/recursion is not allowed for function 'a'/, 'mutual recursion error points at recursive target');
}

{
    my ($status, $out) = run_sup(<<'SUP');
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
SUP
    is($status, 0, 'mutual recursion is allowed for rec functions');
    is($out, "0\n", 'mutual rec recursion can terminate via base case');
}

{
    my ($status, $out) = run_sup(<<'SUP');
return("x")
SUP
    ok($status != 0, 'return(...) outside function fails');
    like($out, qr/return outside function/, 'outside-function return has clear error');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set $who = "Ben"
print("line1\nline2")
print("quote: \" slash: \\ literal: \$who interp: $who")
SUP
    my $expected = "line1\nline2\nquote: \" slash: \\ literal: \$who interp: Ben\n";
    is($status, 0, 'escaped strings execute');
    is($out, $expected, 'string escapes and interpolation work');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set %d = {"api-key": "x", "space key": "y", plain: "z"}
print(dict-get(%d, "api-key"))
print(dict-get(%d, "space key"))
print(dict-get(%d, "plain"))
SUP
    is($status, 0, 'quoted dict keys execute');
    is($out, "x\ny\nz\n", 'quoted and bare dict keys can coexist');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set $k = "dyn"
set %d = {$k: 7}
print(dict-get(%d, "dyn"))
SUP
    is($status, 0, 'dict key expression executes');
    is($out, "7\n", 'dict key expression resolves');
}

{
    my ($status, $out) = run_sup(<<'SUP');
print(concat("a\",b", "X"))
SUP
    is($status, 0, 'escaped quote in arg list executes');
    is($out, "a\",bX\n", 'escaped quote keeps comma inside argument');
}

{
    my $count = 2000;
    my $ones = join(',', (1) x $count);
    my $program = <<"SUP";
set \@seed = [$ones]
set \@xs = []
foreach \$n \@seed
  push(\@xs, \$n)
end
print(len(\@xs))
print(get(\@xs, 1999))
print(pop(\@xs))
print(len(\@xs))
SUP
    my ($status, $out) = run_sup($program);
    is($status, 0, 'large push loop executes');
    is($out, "2000\n1\n1\n1999\n", 'push/get/pop/len stay consistent under load');
}

{
    my ($status, $out) = run_sup(<<'SUP');
$MYGLOBAL = "E3E"
defun show()
  print($MYGLOBAL)
  $MYGLOBAL = "UPDATED"
end
show()
print($MYGLOBAL)
SUP
    is($status, 0, 'global assignment syntax executes');
    is($out, "E3E\nUPDATED\n", 'global vars are visible and mutable across functions');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $mod = File::Spec->catfile($dir, 'moda.sup');
    my $main = File::Spec->catfile($dir, 'main.sup');

    open my $mfh, '>', $mod or die "cannot write $mod: $!";
    print {$mfh} <<'SUP';
set $m = "mod"
defun who($x)
  return(concat(concat($m, ":"), $x))
end
$SHARED = "module"
SUP
    close $mfh;

    open my $fh, '>', $main or die "cannot write $main: $!";
    print {$fh} <<'SUP';
set $m = "main"
defun who($x)
  return(concat(concat($m, ":"), $x))
end
$SHARED = "main"
load("moda")
print(who("A"))
print(moda/who("B"))
print($SHARED)
print($moda/m)
SUP
    close $fh;

    my ($status, $out) = run_file($main);
    is($status, 0, 'module scoping and qualified symbol lookup execute');
    is($out, "main:A\nmod:B\nmodule\nmod\n", 'main symbols stay unqualified, module symbols are qualified, globals are shared');
}

{
    my $dir = tempdir(CLEANUP => 1);
    my $mod = File::Spec->catfile($dir, 'modb.sup');
    my $main = File::Spec->catfile($dir, 'main.sup');

    open my $mfh, '>', $mod or die "cannot write $mod: $!";
    print {$mfh} <<'SUP';
defun only_mod()
  return("x")
end
SUP
    close $mfh;

    open my $fh, '>', $main or die "cannot write $main: $!";
    print {$fh} <<'SUP';
load("modb")
print(only_mod())
SUP
    close $fh;

    my ($status, $out) = run_file($main);
    ok($status != 0, 'module-local functions are not visible unqualified');
    like($out, qr/Unknown function: only_mod/, 'unqualified lookup fails for module-local function');
}

{
    my ($status, $out) = run_sup(<<'SUP');
if eq("a", "a")
  print("x")
SUP
    ok($status != 0, 'missing end in if fails');
    like($out, qr/if without matching end/, 'missing if end has clear error');
}

{
    my ($status, $out) = run_sup(<<'SUP');
when eq("a", "a")
  print("x")
SUP
    ok($status != 0, 'missing end in when fails');
    like($out, qr/when without matching end/, 'missing when end has clear error');
}

{
    my ($status, $out) = run_sup(<<'SUP');
unless eq("a", "a")
  print("x")
SUP
    ok($status != 0, 'missing end in unless fails');
    like($out, qr/unless without matching end/, 'missing unless end has clear error');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun bad($x)
  print($x)
SUP
    ok($status != 0, 'missing end in defun fails');
    like($out, qr/defun without matching end/, 'missing defun end has clear error');
}

{
    my ($status, $out) = run_sup(<<'SUP');
set @x = [1, 2]
foreach $v @x
  print($v)
SUP
    ok($status != 0, 'missing end in foreach fails');
    like($out, qr/foreach without matching end/, 'missing foreach end has clear error');
}

# ============================================================
# Space rule and arg collection tests
# ============================================================

# print a b / print a,b / print (a,b) / print(a,b) — all equivalent (two args)
{
    my ($status, $out) = run_sup(<<'SUP');
defun two(a, b) do
  return concat(a, b)
end
print two("x", "y")
SUP
    is($status, 0, 'space rule: print func args executes');
    is($out, "xy\n", 'space rule: space-separated args work');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun two(a, b) do
  return concat(a, b)
end
print two("x","y")
SUP
    is($status, 0, 'space rule: comma-separated bare args');
    is($out, "xy\n", 'space rule: comma args produce same result');
}

{
    my ($status, $out) = run_sup(<<'SUP');
defun two(a, b) do
  return concat(a, b)
end
print two("x", "y")
print(two("x", "y"))
SUP
    is($status, 0, 'space rule: bare-call and paren-call equivalent');
    is($out, "xy\nxy\n", 'space rule: both forms produce same result');
}

# print (a,b) — paren group with commas spliced as arglist
{
    my ($status, $out) = run_sup(<<'SUP');
print(add(2, 3))
SUP
    is($status, 0, 'space rule: nested call in arglist');
    is($out, "5\n", 'space rule: nested call evaluates correctly');
}

# print (a > b) — allowed, passes infix result
{
    my ($status, $out) = run_sup(<<'SUP');
let a = 10
let b = 3
print (a > b)
SUP
    is($status, 0, 'space rule: spaced paren infix expr allowed');
    is($out, "1\n", 'space rule: infix expr passed as arg');
}

# print(a > b) — rejected with error
{
    my ($status, $out) = run_sup(<<'SUP');
let a = 10
let b = 3
print(a > b)
SUP
    ok($status != 0, 'space rule: print(a > b) rejected');
    like($out, qr/Space rule/, 'space rule: print(a > b) error message');
}

# if(a > b) — rejected with error
{
    my ($status, $out) = run_sup(<<'SUP');
if(1 > 0)
  print("x")
end
SUP
    ok($status != 0, 'space rule: if(...) rejected');
    like($out, qr/not allowed/, 'space rule: if(...) error message');
}

# defun hello(a, b) do — attached parens
{
    my ($status, $out) = run_sup(<<'SUP');
defun greet(name, greeting) do
  return concat(greeting, name)
end
print(greet("world", "hello "))
SUP
    is($status, 0, 'defun with attached parens executes');
    is($out, "hello world\n", 'defun attached parens semantics');
}

# defun hello (a, b) do — spaced parens
{
    my ($status, $out) = run_sup(<<'SUP');
defun greet (name, greeting) do
  return concat(greeting, name)
end
print(greet("world", "hello "))
SUP
    is($status, 0, 'defun with spaced parens executes');
    is($out, "hello world\n", 'defun spaced parens semantics');
}

# defun hello a b do — bare params
{
    my ($status, $out) = run_sup(<<'SUP');
defun greet name greeting do
  return concat(greeting, name)
end
print(greet("world", "hello "))
SUP
    is($status, 0, 'defun with bare params executes');
    is($out, "hello world\n", 'defun bare params semantics');
}

# paren arglist splicing: print (a, b) splices
{
    my ($status, $out) = run_sup(<<'SUP');
print (2, 3)
SUP
    is($status, 0, 'space rule: paren arglist splice executes');
    is($out, "23\n", 'space rule: (a, b) spliced as two args');
}

# call with nested function arg kept together
{
    my ($status, $out) = run_sup(<<'SUP');
let n = 3
print add(n, 2) 5
SUP
    is($status, 0, 'space rule: nested call kept together');
    is($out, "55\n", 'space rule: add(n,2) as one arg, 5 as another');
}

{
    my ($status, $out) = run_file($demo);
    is($status, 0, 'demo.sup executes');
    like($out, qr/-- demo complete --\n/, 'demo.sup reaches completion');
}
