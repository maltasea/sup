
#-----------------------------
# %HASH is the hash to sort
@keys = sort { criterion() } (keys %hash);
foreach $key (@keys) {
    $value = $hash{$key};
    # do something with $key, $value
}
#-----------------------------
foreach $food (sort keys %food_color) {
    print "$food is $food_color{$food}.\n";
}
#-----------------------------
foreach $food (sort { $food_color{$a} cmp $food_color{$b} }
                keys %food_color) 
{
    print "$food is $food_color{$food}.\n";
}
#-----------------------------
@foods = sort { length($food_color{$a}) <=> length($food_color{$b}) } 
    keys %food_color;
foreach $food (@foods) {
    print "$food is $food_color{$food}.\n";
}
#-----------------------------

