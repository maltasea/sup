
#-----------------------------
$value = substr($string, $offset, $count);
$value = substr($string, $offset);

substr($string, $offset, $count) = $newstring;
substr($string, $offset)         = $newtail;
#-----------------------------
# get a 5-byte string, skip 3, then grab 2 8-byte strings, then the rest
($leading, $s1, $s2, $trailing) =
    unpack("A5 x3 A8 A8 A*", $data);

# split at five byte boundaries
@fivers = unpack("A5" x (length($string)/5), $string);

# chop string into individual characters
@chars  = unpack("A1" x length($string), $string);
#-----------------------------
$string = "This is what you have";
#         +012345678901234567890  Indexing forwards  (left to right)
#          109876543210987654321- Indexing backwards (right to left)
#           note that 0 means 10 or 20, etc. above

$first  = substr($string, 0, 1);  # "T"
$start  = substr($string, 5, 2);  # "is"
$rest   = substr($string, 13);    # "you have"
$last   = substr($string, -1);    # "e"
$end    = substr($string, -4);    # "have"
$piece  = substr($string, -8, 3); # "you"
#-----------------------------
$string = "This is what you have";
print $string;
#This is what you have

substr($string, 5, 2) = "wasn't"; # change "is" to "wasn't"
#This wasn't what you have

substr($string, -12)  = "ondrous";# replace last 12 characters
#This wasn't wondrous

substr($string, 0, 1) = "";       # delete first character
#his wasn't wondrous

substr($string, -10)  = "";       # delete last 10 characters
#his wasn'
#-----------------------------
# you can test substrings with =~
if (substr($string, -10) =~ /pattern/) {
    print "Pattern matches in last 10 characters\n";
}

# substitute "at" for "is", restricted to first five characters
substr($string, 0, 5) =~ s/is/at/g;
#-----------------------------
# exchange the first and last letters in a string
$a = "make a hat";
(substr($a,0,1), substr($a,-1)) = (substr($a,-1), substr($a,0,1));
print $a;
# take a ham
#-----------------------------
# extract column with unpack
$a = "To be or not to be";
$b = unpack("x6 A6", $a);  # skip 6, grab 6
print $b;
# or not

($b, $c) = unpack("x6 A2 X5 A2", $a); # forward 6, grab 2; backward 5, grab 2
print "$b\n$c\n";
# or
#
# be
#-----------------------------
sub cut2fmt {
    my(@positions) = @_;
    my $template   = '';
    my $lastpos    = 1;
    foreach $place (@positions) {
        $template .= "A" . ($place - $lastpos) . " ";
        $lastpos   = $place;
    }
    $template .= "A*";
    return $template;
}

$fmt = cut2fmt(8, 14, 20, 26, 30);
print "$fmt\n";
# A7 A6 A6 A6 A4 A*
#-----------------------------

