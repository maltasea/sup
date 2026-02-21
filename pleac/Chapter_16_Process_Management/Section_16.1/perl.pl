
#-----------------------------
$output = `program args`;   # collect output into one multiline string
@output = `program args`;   # collect output into array, one line per element
#-----------------------------
open(README, "program args |") or die "Can't run program: $!\n";
while(<README>) {
    $output .= $_;
}
close(README);
#-----------------------------
`fsck -y /dev/rsd1a`;       # BAD AND SCARY
#-----------------------------
use POSIX qw(:sys_wait_h);

pipe(README, WRITEME);
if ($pid = fork) {
    # parent
    $SIG{CHLD} = sub { 1 while ( waitpid(-1, WNOHANG)) > 0 };
    close(WRITEME);
} else {
    die "cannot fork: $!" unless defined $pid;
    # child
    open(STDOUT, ">&=WRITEME")      or die "Couldn't redirect STDOUT: $!";
    close(README);
    exec($program, $arg1, $arg2)    or die "Couldn't run $program : $!\n";
}

while (<README>) {
    $string .= $_;
    # or  push(@strings, $_);
}
close(README);
#-----------------------------

