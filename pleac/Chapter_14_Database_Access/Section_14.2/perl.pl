
#-----------------------------
dbmopen(%HASH, $FILENAME, 0666)         or die "Can't open FILENAME: $!\n";
%HASH = ();
dbmclose %HASH;
#-----------------------------
use DB_File;

tie(%HASH, "DB_File", $FILENAME)        or die "Can't open FILENAME: $!\n";
%HASH = ();
untie %hash;
#-----------------------------
unlink $FILENAME
    or die "Couldn't unlink $FILENAME to empty the database: $!\n";
dbmopen(%HASH, $FILENAME, 0666)
    or die "Couldn't create $FILENAME database: $!\n";
#-----------------------------

