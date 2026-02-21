
#-----------------------------
my($match, $found, $item);
foreach $item (@array) {
    if ($criterion) {
        $match = $item;  # must save
        $found = 1;
        last;
    }
}
if ($found) {
    ## do something with $match
} else {
    ## unfound
}
#-----------------------------
my($i, $match_idx);
for ($i = 0; $i < @array; $i++) {
    if ($criterion) {
        $match_idx = $i;    # save the index
        last;
    }
}

if (defined $match_idx) {
    ## found in $array[$match_idx]
} else {
    ## unfound
}
#-----------------------------
foreach $employee (@employees) {
    if ( $employee->category() eq 'engineer' ) {
        $highest_engineer = $employee;
        last;
    }
}
print "Highest paid engineer is: ", $highest_engineer->name(), "\n";
#-----------------------------
for ($i = 0; $i < @ARRAY; $i++) {
    last if $criterion;
}
if ($i < @ARRAY) {
    ## found and $i is the index
} else {
    ## not found
}
#-----------------------------

