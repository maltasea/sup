
#-----------------------------
($VAR1, $VAR2) = ($VAR2, $VAR1);
#-----------------------------
$temp    = $a;
$a       = $b;
$b       = $temp;
#-----------------------------
$a       = "alpha";
$b       = "omega";
($a, $b) = ($b, $a);        # the first shall be last -- and versa vice
#-----------------------------
($alpha, $beta, $production) = qw(January March August);
# move beta       to alpha,
# move production to beta,
# move alpha      to production
($alpha, $beta, $production) = ($beta, $production, $alpha);
#-----------------------------

