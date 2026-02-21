
#-----------------------------
printf "It took %d hour%s\n", $time, $time == 1 ? "" : "s";

printf "%d hour%s %s enough.\n", $time, 
        $time == 1 ? ""   : "s",
        $time == 1 ? "is" : "are";
#-----------------------------
printf "It took %d centur%s", $time, $time == 1 ? "y" : "ies";
#-----------------------------
sub noun_plural {
    local $_ = shift;
    # order really matters here!
    s/ss$/sses/                             ||
    s/([psc]h)$/${1}es/                     ||
    s/z$/zes/                               ||
    s/ff$/ffs/                              ||
    s/f$/ves/                               ||
    s/ey$/eys/                              ||
    s/y$/ies/                               ||
    s/ix$/ices/                             ||
    s/([sx])$/$1es/                         ||
    s/$/s/                                  ||
                die "can't get here";
    return $_;
}
*verb_singular = \&noun_plural;   # make function alias
#-----------------------------
use Lingua::EN::Inflect qw(PL classical);
classical(1);               # why isn't this the default?
while (<DATA>) {            # each line in the data
    for (split) {           # each word on the line
        print "One $_, two ", PL($_), ".\n";
    }
} 
# plus one more
$_ = 'secretary general';
print "One $_, two ", PL($_), ".\n";

#__END__
#fish fly ox 
#species genus phylum 
#cherub radius jockey 
#index matrix mythos
#phenomenon formula 
#-----------------------------
#One fish, two fish.
#
#One fly, two flies.
#
#One ox, two oxen.
#
#One species, two species.
#
#One genus, two genera.
#
#One phylum, two phyla.
#
#One cherub, two cherubim.
#
#One radius, two radii.
#
#One jockey, two jockeys.
#
#One index, two indices.
#
#One matrix, two matrices.
#
#One mythos, two mythoi.
#
#One phenomenon, two phenomena.
#
#One formula, two formulae.
#
#One secretary general, two secretaries general.
#-----------------------------

