
#-----------------------------
$/ = '';                      # paragrep mode
while (<>) {
    while ( m{
                \b            # start at a word boundary (begin letters)
                (\S+)         # find chunk of non-whitespace
                \b            # until another word boundary (end letters)
                (
                    \s+       # separated by some whitespace
                    \1        # and that very same chunk again
                    \b        # until another word boundary
                ) +           # one or more sets of those
             }xig
         )
    {
        print "dup word '$1' at paragraph $.\n";
    }
}
#-----------------------------
This is a test
test of the duplicate word finder.
#-----------------------------
$a = 'nobody';
$b = 'bodysnatcher';
if ("$a $b" =~ /^(\w+)(\w+) \2(\w+)$/) {
    print "$2 overlaps in $1-$2-$3\n";
}
body overlaps in no-body-snatcher
#-----------------------------
/^(\w+?)(\w+) \2(\w+)$/, 
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/prime-pattern
#-----------------------------
# solve for 12x + 15y + 16z = 281, maximizing x
if (($X, $Y, $Z)  =
   (('o' x 281)  =~ /^(o*)\1{11}(o*)\2{14}(o*)\3{15}$/))
{
    ($x, $y, $z) = (length($X), length($Y), length($Z));
    print "One solution is: x=$x; y=$y; z=$z.\n";
} else {
    print "No solution.\n";
}
#One solution is: x=17; y=3; z=2.
#-----------------------------
('o' x 281)  =~ /^(o+)\1{11}(o+)\2{14}(o+)\3{15}$/;
#One solution is: x=17; y=3; z=2

('o' x 281)  =~ /^(o*?)\1{11}(o*)\2{14}(o*)\3{15}$/;
#One solution is: x=0; y=7; z=11.

('o' x 281)  =~ /^(o+?)\1{11}(o*)\2{14}(o*)\3{15}$/;
#One solution is: x=1; y=3; z=14.
#-----------------------------

