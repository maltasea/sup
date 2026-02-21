
#-----------------------------
# One fish two fish red fish blue fish
#-----------------------------
$WANT = 3;
$count = 0;
while (/(\w+)\s+fish\b/gi) {
    if (++$count == $WANT) {
        print "The third fish is a $1 one.\n";
        # Warning: don't `last' out of this loop
    }
}
# The third fish is a red one.
#-----------------------------
/(?:\w+\s+fish\s+){2}(\w+)\s+fish/i;
#-----------------------------
# simple way with while loop
$count = 0;
while ($string =~ /PAT/g) {
    $count++;               # or whatever you'd like to do here
}

# same thing with trailing while
$count = 0;
$count++ while $string =~ /PAT/g;

# or with for loop
for ($count = 0; $string =~ /PAT/g; $count++) { }
    
# Similar, but this time count overlapping matches
$count++ while $string =~ /(?=PAT)/g;
#-----------------------------
$pond  = 'One fish two fish red fish blue fish';

# using a temporary
@colors = ($pond =~ /(\w+)\s+fish\b/gi);      # get all matches
$color  = $colors[2];                         # then the one we want

# or without a temporary array
$color = ( $pond =~ /(\w+)\s+fish\b/gi )[2];  # just grab element 3

print "The third fish in the pond is $color.\n";
# The third fish in the pond is red.
#-----------------------------
$count = 0;
$_ = 'One fish two fish red fish blue fish';
@evens = grep { $count++ % 2 == 1 } /(\w+)\s+fish\b/gi;
print "Even numbered fish are @evens.\n";
# Even numbered fish are two blue.
#-----------------------------
$count = 0;
s{
   \b               # makes next \w more efficient
   ( \w+ )          # this is what we'll be changing
   (
     \s+ fish \b
   )
}{
    if (++$count == 4) {
        "sushi" . $2;
    } else {
         $1   . $2;
    }
}gex;
# One fish two fish red fish sushi fish
#-----------------------------
$pond = 'One fish two fish red fish blue fish swim here.';
$color = ( $pond =~ /\b(\w+)\s+fish\b/gi )[-1];
print "Last fish is $color.\n";
# Last fish is blue.
#-----------------------------
m{
    A               # find some pattern A
    (?!             # mustn't be able to find
        .*          # something
        A           # and A
    )
    $               # through the end of the string
}x
#-----------------------------
$pond = 'One fish two fish red fish blue fish swim here.';
if ($pond =~ m{
                    \b  (  \w+) \s+ fish \b
                (?! .* \b fish \b )
            }six )
{
    print "Last fish is $1.\n";
} else {
    print "Failed!\n";
}
# Last fish is blue.
#-----------------------------

