
#-----------------------------
# $c = $a * $b manually
$c_real = ( $a_real * $b_real ) - ( $a_imaginary * $b_imaginary );
$c_imaginary = ( $a_real * $b_imaginary ) + ( $b_real * $a_imaginary );
#-----------------------------
# $c = $a * $b using Math::Complex
use Math::Complex;
$c = $a * $b;
#-----------------------------
$a_real = 3; $a_imaginary = 5;              # 3 + 5i;
$b_real = 2; $b_imaginary = -2;             # 2 - 2i;
$c_real = ( $a_real * $b_real ) - ( $a_imaginary * $b_imaginary );
$c_imaginary = ( $a_real * $b_imaginary ) + ( $b_real * $a_imaginary );
print "c = ${c_real}+${c_imaginary}i\n";

c = 16+4i
#-----------------------------
use Math::Complex;
$a = Math::Complex->new(3,5);               # or Math::Complex->new(3,5);
$b = Math::Complex->new(2,-2);
$c = $a * $b;
print "c = $c\n";

c = 16+4i
#-----------------------------
use Math::Complex;
$c = cplx(3,5) * cplx(2,-2);                # easier on the eye
$d = 3 + 4*i;                               # 3 + 4i
printf "sqrt($d) = %s\n", sqrt($d);

# sqrt(3+4i) = 2+i
#-----------------------------

