
#-----------------------------
sub tan {
    my $theta = shift;

    return sin($theta)/cos($theta);
}
#-----------------------------
use POSIX;

$y = acos(3.7);
#-----------------------------
use Math::Trig;

$y = acos(3.7);
#-----------------------------
eval {
    $y = tan($pi/2);
} or return undef;
#-----------------------------

