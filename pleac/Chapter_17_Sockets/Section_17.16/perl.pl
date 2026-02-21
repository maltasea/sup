
#-----------------------------
$SELF = "/usr/local/libexec/myd";   # which program I am
@ARGS = qw(-l /var/log/myd -d);     # program arguments

$SIG{HUP} = \&phoenix;

sub phoenix {
    # close all your connections, kill your children, and
    # generally prepare to be reincarnated with dignity.
    exec($SELF, @ARGS)              or die "Couldn't restart: $!\n";
}
#-----------------------------
$CONFIG_FILE = "/usr/local/etc/myprog/server_conf.pl";
$SIG{HUP} = \&read_config;
sub read_config {
    do $CONFIG_FILE;
} 
#-----------------------------

