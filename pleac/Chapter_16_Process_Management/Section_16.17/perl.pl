
#-----------------------------
$SIG{INT} = \&got_int;
sub got_int {
    $SIG{INT} = \&got_int;          # but not for SIGCHLD!
    # ...
}
#-----------------------------
my $interrupted = 0;

sub got_int {
    $interrupted = 1;
    $SIG{INT} = 'DEFAULT';          # or 'IGNORE'
    die;
}

eval {
    $SIG{INT} = \&got_int;
    # ... long-running code that you don't want to restart
};

if ($interrupted) {
    # deal with the signal
}
#-----------------------------
$SIG{INT} = \&catcher;
sub catcher {
    $SIG{INT} = \&catcher;
    # ...
}
#-----------------------------
use Config;
print "Hurrah!\n" if $Config{d_sigaction};
#-----------------------------
#% egrep 'S[AV]_(RESTART|INTERRUPT)' /usr/include/*/signal.h
#-----------------------------

