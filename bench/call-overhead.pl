#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time);
use File::Spec;
use File::Temp qw(tempdir);

my $calls = 20_000;
my $iters = 5;
my $warmup = 1;
my $impl = 'perl';
my $sup_path;

GetOptions(
    'calls=i'  => \$calls,
    'iters=i'  => \$iters,
    'warmup=i' => \$warmup,
    'impl=s'   => \$impl,
    'shelm=s'   => \$sup_path,
) or die "Usage: perl bench/call-overhead.pl [--calls N] [--iters N] [--warmup N] [--impl perl|ocaml] [--shelm PATH]\n";

die "--calls must be > 0\n" unless $calls > 0;
die "--iters must be > 0\n" unless $iters > 0;
die "--warmup must be >= 0\n" unless $warmup >= 0;
die "--impl must be one of: perl, ocaml\n" unless $impl eq 'perl' || $impl eq 'ocaml';

my $root = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir()));
if (!defined $sup_path || $sup_path eq '') {
    $sup_path = $impl eq 'perl'
        ? File::Spec->catfile($root, 'shelm.pl')
        : File::Spec->catfile($root, '_build', 'default', 'shelm.exe');
}
die "Cannot find interpreter at $sup_path\n" unless -f $sup_path;
my $runner = $impl eq 'perl' ? ['perl', $sup_path] : [$sup_path];

my $tmp = tempdir(CLEANUP => 1);
my $program_no_fn = File::Spec->catfile($tmp, 'no-function.shlm');
my $program_fn = File::Spec->catfile($tmp, 'with-function.shlm');

my $ones = join(',', (1) x $calls);

write_program(
    $program_no_fn,
    <<"SHELM"
set \@nums = [$ones]
set \$sum = 0
foreach \$n \@nums
  set \$sum = add(\$sum, add(\$n, 1))
end
print(\$sum)
SHELM
);

write_program(
    $program_fn,
    <<"SHELM"
defun inc(\$x)
  return(add(\$x, 1))
end
set \@nums = [$ones]
set \$sum = 0
foreach \$n \@nums
  set \$sum = add(\$sum, inc(\$n))
end
print(\$sum)
SHELM
);

my $base = bench_case('baseline(no-function)', $program_no_fn, $warmup, $iters, $runner);
my $with_fn = bench_case('with-function-calls', $program_fn, $warmup, $iters, $runner);

printf "impl: %s (%s)\n", $impl, $sup_path;
printf "\n%-20s %10s %10s\n", 'case', 'avg(s)', 'calls/s';
printf "%-20s %10.4f %10.0f\n", $base->{name}, $base->{avg_s}, $calls / $base->{avg_s};
printf "%-20s %10.4f %10.0f\n", $with_fn->{name}, $with_fn->{avg_s}, $calls / $with_fn->{avg_s};
printf "\noverhead ratio (with-function / baseline): %.3fx\n", $with_fn->{avg_s} / $base->{avg_s};

sub write_program {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!\n";
    print {$fh} $content;
    close $fh;
}

sub bench_case {
    my ($name, $path, $warmup_runs, $runs, $run_cmd) = @_;
    for (1 .. $warmup_runs) {
        run_program($run_cmd, $path);
    }
    my $sum = 0;
    for (1 .. $runs) {
        my $t0 = time();
        run_program($run_cmd, $path);
        $sum += (time() - $t0);
    }
    return {
        name => $name,
        avg_s => $sum / $runs,
    };
}

sub run_program {
    my ($run_cmd, $path) = @_;
    my @cmd = (@$run_cmd, $path);
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', File::Spec->devnull() or die "cannot open devnull: $!";
        open STDERR, '>', File::Spec->devnull() or die "cannot open devnull: $!";
        exec @cmd or die "exec failed: $!\n";
    }
    waitpid($pid, 0);
    my $status = $? >> 8;
    die "benchmark run failed for $path\n" if $status != 0;
}
