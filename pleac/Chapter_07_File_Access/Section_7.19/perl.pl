
#-----------------------------
open(FH, "<&=$FDNUM");      # open FH to the descriptor itself
open(FH, "<&$FDNUM");       # open FH to a copy of the descriptor

use IO::Handle;

$fh->fdopen($FDNUM, "r");   # open file descriptor 3 for reading
#-----------------------------
use IO::Handle;
$fh = IO::Handle->new();

$fh->fdopen(3, "r");            # open fd 3 for reading
#-----------------------------
$fd = $ENV{MHCONTEXTFD};
open(MHCONTEXT, "<&=$fd")   or die "couldn't fdopen $fd: $!";
# after processing
close(MHCONTEXT)            or die "couldn't close context file: $!";
#-----------------------------

