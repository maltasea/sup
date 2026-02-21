
#-----------------------------
use String::Approx qw(amatch);

if (amatch("PATTERN", @list)) {
    # matched
}

@matches = amatch("PATTERN", @list);
#-----------------------------
use String::Approx qw(amatch);
open(DICT, "/usr/dict/words")               or die "Can't open dict: $!";
while(<DICT>) {
    print if amatch("balast");
}

ballast

balustrade

blast

blastula

sandblast
#-----------------------------

