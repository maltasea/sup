
#-----------------------------
use File::Copy;
copy($oldfile, $newfile);
#-----------------------------
open(IN,  "< $oldfile")                     or die "can't open $oldfile: $!";
open(OUT, "> $newfile")                     or die "can't open $newfile: $!";

$blksize = (stat IN)[11] || 16384;          # preferred block size?
while ($len = sysread IN, $buf, $blksize) {
    if (!defined $len) {
        next if $! =~ /^Interrupted/;       # ^Z and fg
        die "System read error: $!\n";
    }
    $offset = 0;
    while ($len) {          # Handle partial writes.
        defined($written = syswrite OUT, $buf, $len, $offset)
            or die "System write error: $!\n";
        $len    -= $written;
        $offset += $written;
    };
}

close(IN);
close(OUT);
#-----------------------------
system("cp $oldfile $newfile");       # unix
system("copy $oldfile $newfile");     # dos, vms
#-----------------------------
use File::Copy;

copy("datafile.dat", "datafile.bak")
    or die "copy failed: $!";

move("datafile.new", "datafile.dat")
    or die "move failed: $!";
#-----------------------------

