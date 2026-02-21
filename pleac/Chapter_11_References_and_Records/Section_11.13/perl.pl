
#-----------------------------
use Storable; 
store(\%hash, "filename");

# later on...  
$href = retrieve("filename");        # by ref
%hash = %{ retrieve("filename") };   # direct to hash
#-----------------------------
use Storable qw(nstore); 
nstore(\%hash, "filename"); 
# later ...  
$href = retrieve("filename");
#-----------------------------
use Storable qw(nstore_fd);
use Fcntl qw(:DEFAULT :flock);
sysopen(DF, "/tmp/datafile", O_RDWR|O_CREAT, 0666) 
    or die "can't open /tmp/datafile: $!";
flock(DF, LOCK_EX)           or die "can't lock /tmp/datafile: $!";
nstore_fd(\%hash, *DF)
    or die "can't store hash\n";
truncate(DF, tell(DF));
close(DF);
#-----------------------------
use Storable;
use Fcntl qw(:DEFAULT :flock);
open(DF, "< /tmp/datafile")      or die "can't open /tmp/datafile: $!";
flock(DF, LOCK_SH)               or die "can't lock /tmp/datafile: $!";
$href = retrieve(*DF);
close(DF);
#-----------------------------

