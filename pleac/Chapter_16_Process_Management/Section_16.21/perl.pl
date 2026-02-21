
#-----------------------------
$SIG{ALRM} = sub { die "timeout" };

eval {
    alarm(3600);
    # long-time operations here
    alarm(0);
};

if ($@) {
    if ($@ =~ /timeout/) {
                            # timed out; do what you will here
    } else {
        alarm(0);           # clear the still-pending alarm
        die;                # propagate unexpected exception
    } 
} 
#-----------------------------

