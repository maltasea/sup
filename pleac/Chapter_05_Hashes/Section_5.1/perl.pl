
#-----------------------------
$HASH{$KEY} = $VALUE;
#-----------------------------
# %food_color defined per the introduction
$food_color{Raspberry} = "pink";
print "Known foods:\n";
foreach $food (keys %food_color) {
    print "$food\n";
}

# Known foods:
# 
# Banana
# 
# Apple
# 
# Raspberry
# 
# Carrot
# 
# Lemon
#-----------------------------

