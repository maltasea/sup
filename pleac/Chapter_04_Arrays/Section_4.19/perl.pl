
#-----------------------------
#% echo man bites dog | permute
#dog bites man
#
#bites dog man
#
#dog man bites
#
#man dog bites
#
#bites man dog
#
#man bites dog
#-----------------------------
#Set Size            Permutations
#1                   1
#2                   2
#3                   6
#4                   24
#5                   120
#6                   720
#7                   5040
#8                   40320
#9                   362880
#10                  3628800
#11                  39916800
#12                  479001600
#13                  6227020800
#14                  87178291200
#15                  1307674368000
#-----------------------------
use Math::BigInt;
    sub factorial {
    my $n = shift;
    my $s = 1;
    $s *= $n-- while $n > 0;
    return $s;
}
print factorial(Math::BigInt->new("500"));
+1220136... (1035 digits total)
#-----------------------------
# ^^INCLUDE^^ include/perl/ch04/permute
#-----------------------------
# ^^INCLUDE^^ include/perl/ch04/mjd_permute
#-----------------------------

