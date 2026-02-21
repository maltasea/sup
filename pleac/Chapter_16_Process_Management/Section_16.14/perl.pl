
#-----------------------------
kill  9     => $pid;                    # send $pid a signal 9
kill -1     => $pgrp;                   # send whole job a signal 1
kill  USR1  => $$;                      # send myself a SIGUSR1
kill  HUP   => @pids;                   # send a SIGHUP to processes in @pids
#-----------------------------
use POSIX qw(:errno_h);

if (kill 0 => $minion) {
    print "$minion is alive!\n";
} elsif ($! == EPERM) {             # changed uid
    print "$minion has escaped my control!\n";
} elsif ($! == ESRCH) {
    print "$minion is deceased.\n";  # or zombied
} else {
    warn "Odd; I couldn't check on the status of $minion: $!\n";
}
#-----------------------------

