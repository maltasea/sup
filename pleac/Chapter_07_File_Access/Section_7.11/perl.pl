
#-----------------------------
open(FH, "+< $path")                or die "can't open $path: $!";
flock(FH, 2)                        or die "can't flock $path: $!";
# update file, then...
close(FH)                           or die "can't close $path: $!";
#-----------------------------
sub LOCK_SH()  { 1 }     #  Shared lock (for reading)
sub LOCK_EX()  { 2 }     #  Exclusive lock (for writing)
sub LOCK_NB()  { 4 }     #  Non-blocking request (don't stall)
sub LOCK_UN()  { 8 }     #  Free the lock (careful!)
#-----------------------------
unless (flock(FH, LOCK_EX|LOCK_NB)) {
    warn "can't immediately write-lock the file ($!), blocking ...";
    unless (flock(FH, LOCK_EX)) {
        die "can't get write-lock on numfile: $!";
    }
}
#-----------------------------
if ($] < 5.004) {                   # test Perl version number
     my $old_fh = select(FH);
     local $| = 1;                  # enable command buffering
     local $\ = '';                 # clear output record separator
     print "";                      # trigger output flush
     select($old_fh);               # restore previous filehandle
}
flock(FH, LOCK_UN);
#-----------------------------
use Fcntl qw(:DEFAULT :flock);

sysopen(FH, "numfile", O_RDWR|O_CREAT)
                                    or die "can't open numfile: $!";
flock(FH, LOCK_EX)                  or die "can't write-lock numfile: $!";
# Now we have acquired the lock, it's safe for I/O
$num = <FH> || 0;                   # DO NOT USE "or" THERE!!
seek(FH, 0, 0)                      or die "can't rewind numfile : $!";
truncate(FH, 0)                     or die "can't truncate numfile: $!";
print FH $num+1, "\n"               or die "can't write numfile: $!";
close(FH)                           or die "can't close numfile: $!";
#-----------------------------

