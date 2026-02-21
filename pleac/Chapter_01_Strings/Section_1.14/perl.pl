
#-----------------------------
$string =~ s/^\s+//;
$string =~ s/\s+$//;
#-----------------------------
$string = trim($string);
@many   = trim(@many);

sub trim {
    my @out = @_;
    for (@out) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}
#-----------------------------
# print what's typed, but surrounded by >< symbols
while(<STDIN>) {
    chomp;
    print ">$_<\n";
}
#-----------------------------

