
#-----------------------------
while (<>) {
    for $chunk (split) {
        # do something with $chunk
    }
}
#-----------------------------
while (<>) {
    while ( /(\w[\w'-]*)/g ) {  #'
        # do something with $1
    }
}
#-----------------------------
# Make a word frequency count
%seen = ();
while (<>) {
    while ( /(\w['\w-]*)/g ) {  #'
        $seen{lc $1}++;
    }
}

# output hash in a descending numeric sort of its values
foreach $word ( sort { $seen{$b} <=> $seen{$a} } keys %seen) {
    printf "%5d %s\n", $seen{$word}, $word;
}
#-----------------------------
# Line frequency count
%seen = ();
while (<>) {
    $seen{lc $_}++;
}
foreach $line ( sort { $seen{$b} <=> $seen{$a} } keys %seen ) {
    printf "%5d %s", $seen{$line}, $line;
}
#-----------------------------

