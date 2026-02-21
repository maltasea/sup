
#-----------------------------
$ADDRESS = $RECSIZE * $RECNO;
seek(FH, $ADDRESS, 0) or die "seek:$!";
read(FH, $BUFFER, $RECSIZE);
#-----------------------------
$ADDRESS = $RECSIZE * ($RECNO-1);
#-----------------------------

