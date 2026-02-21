
#-----------------------------
chroot("/var/daemon")
    or die "Couldn't chroot to /var/daemon: $!";
#-----------------------------
$pid = fork;
exit if $pid;
die "Couldn't fork: $!" unless defined($pid);
#-----------------------------
use POSIX;

POSIX::setsid()
    or die "Can't start a new session: $!";
#-----------------------------
$time_to_die = 0;

sub signal_handler {
    $time_to_die = 1;
}

$SIG{INT} = $SIG{TERM} = $SIG{HUP} = \&signal_handler;
# trap or ignore $SIG{PIPE}
#-----------------------------
until ($time_to_die) {
    # ...
}
#-----------------------------

