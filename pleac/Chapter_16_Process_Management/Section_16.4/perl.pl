
#-----------------------------
$pid = open(README, "program arguments |")  or die "Couldn't fork: $!\n";
while (<README>) {
    # ...
}
close(README)                               or die "Couldn't close: $!\n";
#-----------------------------
$pid = open(WRITEME, "| program arguments") or die "Couldn't fork: $!\n";
print WRITEME "data\n";
close(WRITEME)                              or die "Couldn't close: $!\n";
#-----------------------------
$pid = open(F, "sleep 100000|");    # child goes to sleep
close(F);                           # and the parent goes to lala land
#-----------------------------
$pid = open(WRITEME, "| program args");
print WRITEME "hello\n";            # program will get hello\n on STDIN
close(WRITEME);                     # program will get EOF on STDIN
#-----------------------------
$pager = $ENV{PAGER} || '/usr/bin/less';  # XXX: might not exist
open(STDOUT, "| $pager");
#-----------------------------

