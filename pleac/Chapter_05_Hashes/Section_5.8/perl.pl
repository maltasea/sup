
#-----------------------------
# %LOOKUP maps keys to values
%REVERSE = reverse %LOOKUP;
#-----------------------------
%surname = ( "Mickey" => "Mantle", "Babe" => "Ruth" );
%first_name = reverse %surname;
print $first_name{"Mantle"}, "\n";
Mickey
#-----------------------------
("Mickey", "Mantle", "Babe", "Ruth")
#-----------------------------
("Ruth", "Babe", "Mantle", "Mickey")
#-----------------------------
("Ruth" => "Babe", "Mantle" => "Mickey")
#-----------------------------
# ^^INCLUDE^^ include/perl/ch05/foodfind
#-----------------------------
# %food_color as per the introduction
while (($food,$color) = each(%food_color)) {
    push(@{$foods_with_color{$color}}, $food);
}

print "@{$foods_with_color{yellow}} were yellow foods.\n";
# Banana Lemon were yellow foods.
#-----------------------------

