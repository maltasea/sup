
#-----------------------------
open (FH, "+< $file")               or die "can't update $file: $!";
while ( <FH> ) {
    $addr = tell(FH) unless eof(FH);
}
truncate(FH, $addr)                 or die "can't truncate $file: $!";
#-----------------------------

