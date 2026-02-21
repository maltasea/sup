#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Spec;

my $slup = File::Spec->catfile($Bin, '..', 'sup.pl');

sub write_text {
    my ($path, $content) = @_;
    my ($vol, $dir, undef) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

sub run_strict {
    my ($path) = @_;
    my $cmd = qq{perl "$slup" --strict-globals "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
global $DB_HOST required
$DB_HOST = "localhost"
print($DB_HOST)
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    is($status, 0, 'strict mode allows declared global assignment');
    is($out, "localhost\n", 'declared global reads successfully in strict mode');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
$UNDECLARED = "x"
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode rejects undeclared global assignment');
    like($out, qr/undeclared global assignment/, 'strict assignment error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
global $DECLARED default("ok")
print($MISSING)
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode rejects undeclared global read');
    like($out, qr/undeclared global read/, 'strict read error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
global $DB_PORT default("5432")
print($DB_PORT)
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    is($status, 0, 'strict mode applies default for declared global');
    is($out, "5432\n", 'declared default is available at runtime');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
print(len(@ARGS))
print(gt(len(dict-keys(%ENV)), 0))
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    is($status, 0, 'strict mode predeclares @ARGS and %ENV');
    is($out, "0\n1\n", 'built-in globals remain usable in strict mode');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
foreach $x @UNDECLARED
  print($x)
end
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode rejects undeclared global array read in foreach');
    like($out, qr/undeclared global read: '\$UNDECLARED'/, 'foreach undeclared global array read is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
set @vals = [1]
foreach $UNDECLARED @vals
  print($UNDECLARED)
end
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode rejects undeclared global foreach iterator assignment');
    like($out, qr/undeclared global assignment: '\$UNDECLARED'/, 'foreach undeclared global iterator assignment is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'mod.sup'), <<'SLUP');
print("mod")
SLUP
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
load("mod")
foreach $x @mod/UNDECLARED
  print($x)
end
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode rejects module-qualified undeclared global array read in foreach');
    like($out, qr/undeclared global read: '\$UNDECLARED'/, 'module-qualified foreach undeclared global array read is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.sup'), <<'SLUP');
global $DB_HOST required
set $path = "mod"
load($path)
SLUP
    my ($status, $out) = run_strict(File::Spec->catfile($dir, 'main.sup'));
    ok($status != 0, 'strict mode uses startup static precheck');
    like($out, qr/static check requires load\("literal"\)/, 'strict mode reports non-static load in precheck');
}

done_testing();
