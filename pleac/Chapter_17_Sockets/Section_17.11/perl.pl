
#-----------------------------
# set up the socket SERVER, bind and listen ...
use POSIX qw(:sys_wait_h);

sub REAPER {
    1 until (-1 == waitpid(-1, WNOHANG));
    $SIG{CHLD} = \&REAPER;                 # unless $] >= 5.002
}

$SIG{CHLD} = \&REAPER;

while ($hisaddr = accept(CLIENT, SERVER)) {
    next if $pid = fork;                    # parent
    die "fork: $!" unless defined $pid;     # failure
    # otherwise child
    close(SERVER);                          # no use to child
    # ... do something
    exit;                                   # child leaves
} continue { 
    close(CLIENT);                          # no use to parent
}
#-----------------------------

