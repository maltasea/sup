
#-----------------------------
%merged = (%A, %B);
#-----------------------------
%merged = ();
while ( ($k,$v) = each(%A) ) {
    $merged{$k} = $v;
}
while ( ($k,$v) = each(%B) ) {
    $merged{$k} = $v;
}
#-----------------------------
# %food_color as per the introduction
%drink_color = ( Galliano  => "yellow",
                 "Mai Tai" => "blue" );

%ingested_color = (%drink_color, %food_color);
#-----------------------------
# %food_color per the introduction, then
%drink_color = ( Galliano  => "yellow",
                 "Mai Tai" => "blue" );

%substance_color = ();
while (($k, $v) = each %food_color) {
    $substance_color{$k} = $v;
} 
while (($k, $v) = each %drink_color) {
    $substance_color{$k} = $v;
} 
#-----------------------------
foreach $substanceref ( \%food_color, \%drink_color ) {
    while (($k, $v) = each %$substanceref) {
        $substance_color{$k} = $v;
    }
}
#-----------------------------
foreach $substanceref ( \%food_color, \%drink_color ) {
    while (($k, $v) = each %$substanceref) {
        if (exists $substance_color{$k}) {
            print "Warning: $k seen twice.  Using the first definition.\n";
            next;
        }
        $substance_color{$k} = $v;
    }
}
#-----------------------------
@all_colors{keys %new_colors} = values %new_colors;
#-----------------------------

