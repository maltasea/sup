
#-----------------------------
$this_function = (caller(0))[3];
#-----------------------------
($package, $filename, $line, $subr, $has_args, $wantarray )= caller($i);
#   0         1         2       3       4          5
#-----------------------------
$me  = whoami();
$him = whowasi();

sub whoami  { (caller(1))[3] }
sub whowasi { (caller(2))[3] }
#-----------------------------

