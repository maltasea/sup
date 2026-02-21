
#-----------------------------
use MLDBM qw(DB_File);
use Fcntl;                            

tie(%hash, 'MLDBM', 'testfile.db', O_CREAT|O_RDWR, 0666)
    or die "can't open tie to testfile.db: $!";

# ... act on %hash

untie %hash;
#-----------------------------
use MLDBM qw(DB_File);
use Fcntl;                            
tie(%hash, 'MLDBM', 'testfile.db', O_CREAT|O_RDWR, 0666)
    or die "can't open tie to testfile.db: $!";
#-----------------------------
# this doesn't work!
$hash{"some key"}[4] = "fred";

# RIGHT
$aref = $hash{"some key"};
$aref->[4] = "fred";
$hash{"some key"} = $aref;
#-----------------------------

