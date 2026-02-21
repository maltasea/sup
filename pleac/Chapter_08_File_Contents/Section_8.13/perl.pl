
#-----------------------------
use Fcntl;                          # for SEEK_SET and SEEK_CUR

$ADDRESS = $RECSIZE * $RECNO;
seek(FH, $ADDRESS, SEEK_SET)        or die "Seeking: $!";
read(FH, $BUFFER, $RECSIZE) == $RECSIZE
                                    or die "Reading: $!";
@FIELDS = unpack($FORMAT, $BUFFER);
# update fields, then
$BUFFER = pack($FORMAT, @FIELDS);
seek(FH, -$RECSIZE, SEEK_CUR)       or die "Seeking: $!";
print FH $BUFFER;
close FH                            or die "Closing: $!";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/weekearly
#-----------------------------

