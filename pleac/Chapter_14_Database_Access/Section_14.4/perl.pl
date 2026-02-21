
#-----------------------------
%OUTPUT = (%INPUT1, %INPUT2);
#-----------------------------
%OUTPUT = ();
foreach $href ( \%INPUT1, \%INPUT2 ) {
    while (my($key, $value) = each(%$href)) {
        if (exists $OUTPUT{$key}) {
            # decide which value to use and set $OUTPUT{$key} if necessary
        } else {
            $OUTPUT{$key} = $value;
        }
    }
}
#-----------------------------

