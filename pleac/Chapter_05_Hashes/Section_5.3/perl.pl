
#-----------------------------
# remove $KEY and its value from %HASH
delete($HASH{$KEY});
#-----------------------------
# %food_color as per Introduction
sub print_foods {
    my @foods = keys %food_color;
    my $food;

    print "Keys: @foods\n";
    print "Values: ";

    foreach $food (@foods) {
        my $color = $food_color{$food};

        if (defined $color) {
            print "$color ";
        } else {
            print "(undef) ";
        }
    }
    print "\n";
}

print "Initially:\n";
print_foods();


print "\nWith Banana undef\n";
undef $food_color{"Banana"};
print_foods();


print "\nWith Banana deleted\n";
delete $food_color{"Banana"};
print_foods();


# Initially:
# 
# Keys: Banana Apple Carrot Lemon
# 
# Values: yellow red orange yellow 
# 
# 
# With Banana undef
# 
# Keys: Banana Apple Carrot Lemon
# 
# Values: (undef) red orange yellow 
# 
# 
# With Banana deleted
# 
# Keys: Apple Carrot Lemon
# 
# Values: red orange yellow 
#-----------------------------
delete @food_color{"Banana", "Apple", "Cabbage"};
#-----------------------------

