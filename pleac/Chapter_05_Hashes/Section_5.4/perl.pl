
#-----------------------------
while(($key, $value) = each(%HASH)) {
    # do something with $key and $value
}
#-----------------------------
foreach $key (keys %HASH) {
    $value = $HASH{$key};
    # do something with $key and $value
}
#-----------------------------
# %food_color per the introduction
while(($food, $color) = each(%food_color)) {
    print "$food is $color.\n";
}
# Banana is yellow.
# 
# Apple is red.
# 
# Carrot is orange.
# 
# Lemon is yellow.

foreach $food (keys %food_color) {
    my $color = $food_color{$food};
    print "$food is $color.\n";
}
# Banana is yellow.
# 
# Apple is red.
# 
# Carrot is orange.
# 
# Lemon is yellow.
#-----------------------------
print
 
"$food
 
is
 
$food_color{$food}.\n"
 
#-----------------------------
foreach $food (sort keys %food_color) {
    print "$food is $food_color{$food}.\n";
}
# Apple is red.
# 
# Banana is yellow.
# 
# Carrot is orange.
# 
# Lemon is yellow.
#-----------------------------
while ( ($k,$v) = each %food_color ) {
    print "Processing $k\n";
    keys %food_color;               # goes back to the start of %food_color
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch05/countfrom
#-----------------------------

