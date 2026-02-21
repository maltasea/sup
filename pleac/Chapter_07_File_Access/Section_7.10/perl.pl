
#-----------------------------
open(FH, "+< FILE")                 or die "Opening: $!";
@ARRAY = <FH>;
# change ARRAY here
seek(FH,0,0)                        or die "Seeking: $!";
print FH @ARRAY                     or die "Printing: $!";
truncate(FH,tell(FH))               or die "Truncating: $!";
close(FH)                           or die "Closing: $!";
#-----------------------------
open(F, "+< $infile")       or die "can't read $infile: $!";
$out = '';
while (<F>) {
    s/DATE/localtime/eg;
    $out .= $_;
}
seek(F, 0, 0)               or die "can't seek to start of $infile: $!";
print F $out                or die "can't print to $infile: $!";
truncate(F, tell(F))        or die "can't truncate $infile: $!";
close(F)                    or die "can't close $infile: $!";
#-----------------------------

