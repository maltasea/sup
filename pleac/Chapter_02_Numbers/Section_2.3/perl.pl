
#-----------------------------
$rounded = sprintf("%FORMATf", $unrounded);
#-----------------------------
$a = 0.255;
$b = sprintf("%.2f", $a);
print "Unrounded: $a\nRounded: $b\n";
printf "Unrounded: $a\nRounded: %.2f\n", $a;

# Unrounded: 0.255
# 
# Rounded: 0.26
# 
# Unrounded: 0.255
# 
# Rounded: 0.26
#-----------------------------
use POSIX;
print "number\tint\tfloor\tceil\n";
@a = ( 3.3 , 3.5 , 3.7, -3.3 );
foreach (@a) {
    printf( "%.1f\t%.1f\t%.1f\t%.1f\n", 
        $_, int($_), floor($_), ceil($_) );
}

# number  int     floor   ceil
# 
#  3.3     3.0     3.0     4.0
# 
#  3.5     3.0     3.0     4.0
# 
#  3.7     3.0     3.0     4.0
# 
# -3.3    -3.0    -4.0    -3.0
#-----------------------------

