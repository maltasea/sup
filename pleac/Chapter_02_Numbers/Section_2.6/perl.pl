
#-----------------------------
use Roman;
$roman = roman($arabic);                        # convert to roman numerals
$arabic = arabic($roman) if isroman($roman);    # convert from roman numerals
#-----------------------------
use Roman;
$roman_fifteen = roman(15);                         # "xv"
print "Roman for fifteen is $roman_fifteen\n";
$arabic_fifteen = arabic($roman_fifteen);
print "Converted back, $roman_fifteen is $arabic_fifteen\n";

Roman for fifteen is xv

Converted back, xv is 15
#-----------------------------

