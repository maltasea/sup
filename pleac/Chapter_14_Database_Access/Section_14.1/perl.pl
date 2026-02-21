
#-----------------------------
use DB_File;                      # optional; overrides default
dbmopen %HASH, $FILENAME, 0666    # open database, accessed through %HASH
    or die "Can't open $FILENAME: $!\n";

$V = $HASH{$KEY};                 # retrieve from database
$HASH{$KEY} = $VALUE;             # put value into database
if (exists $HASH{$KEY}) {         # check whether in database
    # ...
}
delete $HASH{$KEY};               # remove from database
dbmclose %HASH;                   # close the database
#-----------------------------
use DB_File;                      # load database module

tie %HASH, "DB_File", $FILENAME   # open database, to be accessed
    or die "Can't open $FILENAME:$!\n";    # through %HASH

$V = $HASH{$KEY};                 # retrieve from database
$HASH{$KEY} = $VALUE;             # put value into database
if (exists $HASH{$KEY}) {         # check whether in database
    # ...
}
delete $HASH{$KEY};               # delete from database
untie %hash;                      # close the database
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/userstats
#-----------------------------
gnat     ttyp1   May 29 15:39   (coprolith.frii.com)
#-----------------------------

