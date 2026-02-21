
#-----------------------------
foreach $item (LIST) {
    # do something with $item
}
#-----------------------------
foreach $user (@bad_users) {
        complain($user);
}
#-----------------------------
foreach $var (sort keys %ENV) {
    print "$var=$ENV{$var}\n";
}
#-----------------------------
foreach $user (@all_users) {
    $disk_space = get_usage($user);     # find out how much disk space in use
    if ($disk_space > $MAX_QUOTA) {     # if it's more than we want ...
        complain($user);                # ... then object vociferously
    }
}
#-----------------------------
foreach (`who`) {
    if (/tchrist/) {
        print;
    }
}
#-----------------------------
while (<FH>) {              # $_ is set to the line just read
    chomp;                  # $_ has a trailing \n removed, if it had one
    foreach (split) {       # $_ is split on whitespace, into @_
                            # then $_ is set to each chunk in turn
        $_ = reverse;       # the characters in $_ are reversed
        print;              # $_ is printed
    }
}
#-----------------------------
foreach my $item (@array) {
    print "i = $item\n";
}
#-----------------------------
@array = (1,2,3);
foreach $item (@array) {
    $item--;
}
print "@array\n";
0 1 2


# multiply everything in @a and @b by seven
@a = ( .5, 3 ); @b =( 0, 1 );
foreach $item (@a, @b) {
    $item *= 7;
}
print "@a @b\n";
3.5 21 0 7
#-----------------------------
# trim whitespace in the scalar, the array, and all the values
# in the hash
foreach ($scalar, @array, @hash{keys %hash}) {
    s/^\s+//;
    s/\s+$//;
}
#-----------------------------
for $item (@array) {  # same as foreach $item (@array)
    # do something
}

for (@array)      {   # same as foreach $_ (@array)
    # do something
}
#-----------------------------

