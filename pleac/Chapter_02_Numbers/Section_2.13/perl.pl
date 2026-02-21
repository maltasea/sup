
#-----------------------------
$log_e = log(VALUE);
#-----------------------------
use POSIX qw(log10);
$log_10 = log10(VALUE);
#-----------------------------
sub log_base {
    my ($base, $value) = @_;
    return log($value)/log($base);
}
#-----------------------------
# log_base defined as above
$answer = log_base(10, 10_000);
print "log10(10,000) = $answer\n";
# log10(10,000) = 4
#-----------------------------
use Math::Complex;
printf "log2(1024) = %lf\n", logn(1024, 2); # watch out for argument order!
# log2(1024) = 10.000000
#-----------------------------

