
#-----------------------------
@array_of_scalar_refs = ( \$a, \$b );
#-----------------------------
@array_of_scalar_refs = \( $a, $b );
#-----------------------------
${ $array_of_scalar_refs[1] } = 12;         # $b = 12
#-----------------------------
($a, $b, $c, $d) = (1 .. 4);        # initialize
@array =  (\$a, \$b, \$c, \$d);     # refs to each scalar
@array = \( $a,  $b,  $c,  $d);     # same thing!
@array = map { \my $anon } 0 .. 3;  # allocate 4 anon scalarresf

${ $array[2] } += 9;                # $c now 12

${ $array[ $#array ] } *= 5;        # $d now 20
${ $array[-1] }        *= 5;        # same; $d now 100

$tmp   = $array[-1];                # using temporary
$$tmp *= 5;                         # $d now 500
#-----------------------------
use Math::Trig qw(pi);              # load the constant pi
foreach $sref (@array) {            # prepare to change $a,$b,$c,$d
    ($$sref **= 3) *= (4/3 * pi);   # replace with spherical volumes
}
#-----------------------------

