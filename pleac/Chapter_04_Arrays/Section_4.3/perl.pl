
#-----------------------------
# grow or shrink @ARRAY
$#ARRAY = $NEW_LAST_ELEMENT_INDEX_NUMBER;
#-----------------------------
$ARRAY[$NEW_LAST_ELEMENT_INDEX_NUMBER] = $VALUE;
#-----------------------------
sub what_about_that_array {
    print "The array now has ", scalar(@people), " elements.\n";
    print "The index of the last element is $#people.\n";
    print "Element #3 is `$people[3]'.\n";
}

@people = qw(Crosby Stills Nash Young);
what_about_that_array();
#-----------------------------
The array now has 4 elements.

The index of the last element is 3.

Element #3 is `Young'.
#-----------------------------
$#people--;
what_about_that_array();
#-----------------------------
The array now has 3 elements.

The index of the last element is 2.

Element #3 is `'.
#-----------------------------
$#people = 10_000;
what_about_that_array();
#-----------------------------
The array now has 10001 elements.

The index of the last element is 10000.

Element #3 is `'.
#-----------------------------
$people[10_000] = undef;
#-----------------------------

