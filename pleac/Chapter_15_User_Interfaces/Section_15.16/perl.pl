
#-----------------------------
use Tk;

$main = MainWindow->new();

$main->bind('<Configure>' => sub {
    $xe = $main->XEvent;
    $main->maxsize($xe->w, $xe->h);
    $main->minsize($xe->w, $xe->h);
});
#-----------------------------
$widget->pack( -fill => "both", -expand => 1 );
$widget->pack( -fill => "x",    -expand => 1 );
#-----------------------------
$mainarea->pack( -fill => "both", -expand => 1);
#-----------------------------
$menubar->pack( -fill => "x", -expand => 1 );
#-----------------------------
$menubar->pack (-fill     => "x",
                -expand   => 1,
                -anchor   => "nw" );
#-----------------------------

