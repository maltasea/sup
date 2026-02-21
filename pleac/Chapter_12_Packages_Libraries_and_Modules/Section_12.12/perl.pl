
#-----------------------------
sub even_only {
    my $n = shift;
    die "$n is not even" if $n & 1;  # one way to test
    #....
}
#-----------------------------
use Carp;
sub even_only {
    my $n = shift;
    croak "$n is not even" if $n % 2;  # here's another
    #....
}
#-----------------------------
use Carp;
sub even_only {
    my $n = shift;
    if ($n & 1) {         # test whether odd number
        carp "$n is not even, continuing";
        ++$n;
    }
    #....
}
#-----------------------------
carp "$n is not even, continuing" if $^W;
#-----------------------------

