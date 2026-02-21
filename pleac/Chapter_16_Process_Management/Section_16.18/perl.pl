
#-----------------------------
$SIG{INT} = 'IGNORE';
#-----------------------------
$SIG{INT} = \&tsktsk;

sub tsktsk {
    $SIG{INT} = \&tsktsk;           # See ``Writing A Signal Handler''
    warn "\aThe long habit of living indisposeth us for dying.\n";
}
#-----------------------------
#% stty -a
#speed 9600 baud; 38 rows; 80 columns;
#
#lflags: icanon isig iexten echo echoe -echok echoke -echonl echoctl
#
#	-echoprt -altwerase -noflsh -tostop -flusho pendin -nokerninfo
#
#	-extproc
#
#iflags: -istrip icrnl -inlcr -igncr ixon -ixoff ixany imaxbel -ignbrk
#
#	 brkint -inpck -ignpar -parmrk
#
#oflags: opost onlcr oxtabs
#
#cflags: cread cs8 -parenb -parodd hupcl -clocal -cstopb -crtscts -dsrflow
#
#	 -dtrflow -mdmbuf
#
#cchars: discard = ^O; dsusp = ^Y; eof = ^D; eol = <undef;>
#
#	 eol2 = <undef; erase = ^H; intr = ^C; kill = ^U; lnext = ^V;>
#
#	 min = 1; quit = ^\; reprint = ^R; start = ^Q; status = <undef;>
#
#	 stop = ^S; susp = ^Z; time = 0; werase = ^W;
#-----------------------------

