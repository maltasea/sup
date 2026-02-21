
#-----------------------------
use Tie::IxHash;
tie %HASH, "Tie::IxHash";
# manipulate %HASH
@keys = keys %HASH;         # @keys is in insertion order
#-----------------------------
# initialize
use Tie::IxHash;

tie %food_color, "Tie::IxHash";
$food_color{Banana} = "Yellow";
$food_color{Apple}  = "Green";
$food_color{Lemon}  = "Yellow";

print "In insertion order, the foods are:\n";
foreach $food (keys %food_color) {
    print "  $food\n";
}

print "Still in insertion order, the foods' colors are:\n";
while (( $food, $color ) = each %food_color ) {
    print "$food is colored $color.\n";
}

#In insertion order, the foods are:
#
#  Banana
#
#  Apple
#
#  Lemon
#
#Still in insertion order, the foods' colors are:
#
#Banana is colored Yellow.
#
#Apple is colored Green.
#
#Lemon is colored Yellow.
#-----------------------------

