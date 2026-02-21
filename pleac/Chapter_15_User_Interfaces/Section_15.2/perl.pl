
#-----------------------------
sub I_am_interactive {
    return -t STDIN && -t STDOUT;
}
#-----------------------------
use POSIX qw/getpgrp tcgetpgrp/;

sub I_am_interactive {
    local *TTY;  # local file handle
    open(TTY, "/dev/tty") or die "can't open /dev/tty: $!";
    my $tpgrp = tcgetpgrp(fileno(TTY));
    my $pgrp  = getpgrp();
    close TTY;
    return ($tpgrp == $pgrp);
}
#-----------------------------
while (1) {
    if (I_am_interactive()) {
        print "Prompt: ";
    }
    $line = <STDIN>;
    last unless defined $line; 
    # do something with the line
}
#-----------------------------
sub prompt { print "Prompt: " if I_am_interactive() }
for (prompt(); $line = <STDIN>; prompt()) {
    # do something with the line
} 
#-----------------------------

