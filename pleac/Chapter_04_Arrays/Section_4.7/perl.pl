
#-----------------------------
# assume @A and @B are already loaded
%seen = ();                  # lookup table to test membership of B
@aonly = ();                 # answer

# build lookup table
foreach $item (@B) { $seen{$item} = 1 }

# find only elements in @A and not in @B
foreach $item (@A) {
    unless ($seen{$item}) {
        # it's not in %seen, so add to @aonly
        push(@aonly, $item);
    }
}
#-----------------------------
my %seen; # lookup table
my @aonly;# answer

# build lookup table
@seen{@B} = ();

foreach $item (@A) {
    push(@aonly, $item) unless exists $seen{$item};
}
#-----------------------------
foreach $item (@A) {
    push(@aonly, $item) unless $seen{$item};
    $seen{$item} = 1;                       # mark as seen
}
#-----------------------------
$hash{"key1"} = 1;
$hash{"key2"} = 2;
#-----------------------------
@hash{"key1", "key2"} = (1,2);
#-----------------------------
@seen{@B} = ();
#-----------------------------
@seen{@B} = (1) x @B;
#-----------------------------

