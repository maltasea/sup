
#-----------------------------
use POSIX qw(:signal_h);

$sigset = POSIX::SigSet->new(SIGINT);    # define the signals to block
$old_sigset = POSIX::SigSet->new;        # where the old sigmask will be kept

unless (defined sigprocmask(SIG_BLOCK, $sigset, $old_sigset)) {
    die "Could not block SIGINT\n";
}
#-----------------------------
unless (defined sigprocmask(SIG_UNBLOCK, $old_sigset)) {
    die "Could not unblock SIGINT\n";
}
#-----------------------------
use POSIX qw(:signal_h);

$sigset = POSIX::SigSet->new( SIGINT, SIGKILL );
#-----------------------------

