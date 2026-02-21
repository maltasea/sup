
#-----------------------------
# equal(NUM1, NUM2, ACCURACY) : returns true if NUM1 and NUM2 are
# equal to ACCURACY number of decimal places

sub equal {
    my ($A, $B, $dp) = @_;

    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
  }
#-----------------------------
$wage = 536;                # $5.36/hour
$week = 40 * $wage;         # $214.40
printf("One week's wage is: \$%.2f\n", $week/100);
#
#One week's wage is: $214.40
#-----------------------------

