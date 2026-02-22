#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Spec;

my $sup = File::Spec->catfile($Bin, '..', 'shelm.pl');

sub write_text {
    my ($path, $content) = @_;
    my ($vol, $dir, undef) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

sub run_check {
    my ($path) = @_;
    my $cmd = qq{perl "$sup" --check "$path" 2>&1};
    my $out = `$cmd`;
    my $status = $? >> 8;
    return ($status, $out);
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'mod.shlm'), <<'SHELM');
$DB_HOST = "localhost"
SHELM
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
global $DB_HOST required
load("mod")
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    is($status, 0, 'required global assigned through load() passes static check');
    is($out, '', 'successful static check is silent');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
global $API_KEY required
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    ok($status != 0, 'missing required global fails static check');
    like($out, qr/required global is never assigned: '\$API_KEY'/, 'missing required global error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
$UNDECLARED = "x"
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    ok($status != 0, 'undeclared global assignment fails static check');
    like($out, qr/undeclared global assignment: '\$UNDECLARED'/, 'undeclared assignment error is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
global $db_host required
$db_host = "localhost"
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    ok($status != 0, 'non-uppercase global declaration fails static check');
    like($out, qr/global name must be uppercase/, 'global declaration naming rule is clear');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
global $DB_PORT default("5432")
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    is($status, 0, 'declared global with default passes without assignment');
    is($out, '', 'default declaration passes without errors');
}

{
    my $dir = tempdir(CLEANUP => 1);
    write_text(File::Spec->catfile($dir, 'main.shlm'), <<'SHELM');
global $DB_HOST required
set $path = "mod"
load($path)
SHELM
    my ($status, $out) = run_check(File::Spec->catfile($dir, 'main.shlm'));
    ok($status != 0, 'dynamic load fails static check');
    like($out, qr/static check requires load\("literal"\)/, 'dynamic load limitation is reported clearly');
}

done_testing();
