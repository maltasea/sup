
#-----------------------------
%seen = ();
@uniq = ();
foreach $item (@list) {
    unless ($seen{$item}) {
        # if we get here, we have not seen it before
        $seen{$item} = 1;
        push(@uniq, $item);
    }
}
#-----------------------------
%seen = ();
foreach $item (@list) {
    push(@uniq, $item) unless $seen{$item}++;
}
#-----------------------------
%seen = ();
foreach $item (@list) {
    some_func($item) unless $seen{$item}++;
}
#-----------------------------
%seen = ();
foreach $item (@list) {
    $seen{$item}++;
}
@uniq = keys %seen;
#-----------------------------
%seen = ();
@uniqu = grep { ! $seen{$_} ++ } @list;
#-----------------------------
# generate a list of users logged in, removing duplicates
%ucnt = ();
for (`who`) {
    s/\s.*\n//;   # kill from first space till end-of-line, yielding username
    $ucnt{$_}++;  # record the presence of this user
}
# extract and print unique keys
@users = sort keys %ucnt;
print "users logged in: @users\n";
#-----------------------------

