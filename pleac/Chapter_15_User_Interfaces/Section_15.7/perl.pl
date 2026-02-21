
#-----------------------------
print "\aWake up!\n";
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
$vb = "";
eval {
    $terminal->Trequire("vb");
    $vb = $terminal->Tputs('vb', 1);
};

print $vb;                                  # ring visual bell
#-----------------------------

