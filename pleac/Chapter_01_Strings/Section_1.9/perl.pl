
#-----------------------------
use locale;                     # needed in 5.004 or above

$big = uc($little);             # "bo peep" -> "BO PEEP"
$little = lc($big);             # "JOHN"    -> "john"
$big = "\U$little";             # "bo peep" -> "BO PEEP"
$little = "\L$big";             # "JOHN"    -> "john"
#-----------------------------
$big = "\u$little";             # "bo"      -> "Bo"
$little = "\l$big";             # "BoPeep"    -> "boPeep" 
#-----------------------------
use locale;                     # needed in 5.004 or above

$beast   = "dromedary";
# capitalize various parts of $beast
$capit   = ucfirst($beast);         # Dromedary
$capit   = "\u\L$beast";            # (same)
$capall  = uc($beast);              # DROMEDARY
$capall  = "\U$beast";              # (same)
$caprest = lcfirst(uc($beast));     # dROMEDARY
$caprest = "\l\U$beast";            # (same)
#-----------------------------
# capitalize each word's first character, downcase the rest
$text = "thIS is a loNG liNE";
$text =~ s/(\w+)/\u\L$1/g;
print $text;
This Is A Long Line
#-----------------------------
if (uc($a) eq uc($b)) {
    print "a and b are the same\n";
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/randcap

#% randcap < genesis | head -9
#boOk 01 genesis
#
#
#001:001 in the BEginning goD created the heaven and tHe earTh.
#
#    
#
#001:002 and the earth wAS without ForM, aND void; AnD darkneSS was
#
#	 upon The Face of the dEEp. and the spIrit of GOd movEd upOn
#
#	 tHe face of the Waters.
#
#
#001:003 and god Said, let there be ligHt: and therE wAs LigHt.
#-----------------------------
sub randcase {
    rand(100) < 20 ? ("\040" ^ $_[0]) : $_[0];
}
#-----------------------------
$string &= "\177" x length($string);
#-----------------------------

