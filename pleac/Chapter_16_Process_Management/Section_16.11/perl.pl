
#-----------------------------
#% mkfifo /path/to/named.pipe
#-----------------------------
open(FIFO, "< /path/to/named.pipe")         or die $!;
while (<FIFO>) {
    print "Got: $_";
}
close(FIFO);
#-----------------------------
open(FIFO, "> /path/to/named.pipe")         or die $!;
print FIFO "Smoke this.\n";
close(FIFO);
#-----------------------------
#% mkfifo ~/.plan                    # isn't this everywhere yet?
#% mknod  ~/.plan p                  # in case you don't have mkfifo
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/dateplan
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/fifolog
#-----------------------------
use POSIX qw(:errno_h);

$SIG{PIPE} = 'IGNORE';
# ...
$status = print FIFO "Are you there?\n";
if (!$status && $! == EPIPE) {
    warn "My reader has forsaken me!\n";
    next;
}
#-----------------------------
use POSIX;
print _POSIX_PIPE_BUF, "\n";
#-----------------------------

