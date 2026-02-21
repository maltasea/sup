
#-----------------------------
use Term::Cap;

$OSPEED = 9600;
eval {
    require POSIX;
    my $termios = POSIX::Termios->new();
    $termios->getattr;
    $OSPEED = $termios->getospeed;
};

$terminal = Term::Cap->Tgetent({OSPEED=>$OSPEED});
$terminal->Tputs('cl', 1, STDOUT);
#-----------------------------
system("clear");
#-----------------------------
$clear = $terminal->Tputs('cl');
$clear = `clear`;
#-----------------------------
print $clear;
#-----------------------------

