
#-----------------------------
array_diff( \@array1, \@array2 );
#-----------------------------
@a = (1, 2);
@b = (5, 8);
@c = add_vecpair( \@a, \@b );
print "@c\n";
6 10
 

sub add_vecpair {       # assumes both vectors the same length
    my ($x, $y) = @_;   # copy in the array references
    my @result;

    for (my $i=0; $i < @$x; $i++) {
      $result[$i] = $x->[$i] + $y->[$i];
    }

    return @result;
}
#-----------------------------
unless (@_ == 2 && ref($x) eq 'ARRAY' && ref($y) eq 'ARRAY') {
    die "usage: add_vecpair ARRAYREF1 ARRAYREF2";
}
#-----------------------------

