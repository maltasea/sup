
#-----------------------------
$Logfile = "/tmp/mylog" unless defined $Logfile;
open(LF, ">>$Logfile")
    or die "can't append to $Logfile: $!";
select(((select(LF), $|=1))[0]);  # unbuffer LF
logmsg("startup");

sub logmsg {
    my $now = scalar gmtime;
    print LF "$0 $$ $now: @_\n"
        or die "write to $Logfile failed: $!";
}

END {
    logmsg("shutdown");
    close(LF)                     
        or die "close $Logfile failed: $!";
}
#-----------------------------
use sigtrap qw(die normal-signals error-signals);
#-----------------------------

