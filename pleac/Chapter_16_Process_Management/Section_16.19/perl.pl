
#-----------------------------
$SIG{CHLD} = 'IGNORE';
#-----------------------------
use POSIX ":sys_wait_h";

$SIG{CHLD} = \&REAPER;
sub REAPER {
    my $stiff;
    while (($stiff = waitpid(-1, &WNOHANG)) > 0) {
        # do something with $stiff if you want
    }
    $SIG{CHLD} = \&REAPER;                  # install *after* calling waitpid
}
#-----------------------------
$exit_value  = $? >> 8;
$signal_num  = $? & 127;
$dumped_core = $? & 128;
#-----------------------------
use POSIX qw(:signal_h :errno_h :sys_wait_h);

$SIG{CHLD} = \&REAPER;
sub REAPER {
    my $pid;

    $pid = waitpid(-1, &WNOHANG);

    if ($pid == -1) {
        # no child waiting.  Ignore it.
    } elsif (WIFEXITED($?)) {
        print "Process $pid exited.\n";
    } else {
        print "False alarm on $pid.\n";
    }
    $SIG{CHLD} = \&REAPER;          # in case of unreliable signals
}
#-----------------------------
use Config;
$has_nonblocking = $Config{d_waitpid} eq "define" ||
                   $Config{d_wait4}   eq "define";
#-----------------------------

