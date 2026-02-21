
#-----------------------------
%seen = ();

sub do_my_thing {
    my $filename = shift;
    my ($dev, $ino) = stat $filename;

    unless ($seen{$dev, $ino}++) {
        # do something with $filename because we haven't
        # seen it before
    }
}
#-----------------------------
foreach $filename (@files) {
    ($dev, $ino) = stat $filename;
    push( @{ $seen{$dev,$ino} }, $filename);
}

foreach $devino (sort keys %seen) {
    ($dev, $ino) = split(/$;/o, $devino);
    if (@{$seen{$devino}} > 1) {
        # @{$seen{$devino}} is a list of filenames for the same file
    }
}
#-----------------------------

