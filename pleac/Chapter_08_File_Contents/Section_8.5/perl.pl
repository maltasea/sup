
#-----------------------------
for (;;) {
    while (<FH>) { .... }
    sleep $SOMETIME;
    seek(FH, 0, 1);
}
#-----------------------------
use IO::Seekable;

for (;;) {
    while (<FH>) { .... }
    sleep $SOMETIME;
    FH->clearerr();
}
#-----------------------------
$naptime = 1;

use IO::Handle;
open (LOGFILE, "/tmp/logfile") or die "can't open /tmp/logfile: $!";
for (;;) {
    while (<LOGFILE>) { print }     # or appropriate processing
    sleep $naptime;
    LOGFILE->clearerr();            # clear stdio error flag
}
#-----------------------------
for (;;) {
    for ($curpos = tell(LOGFILE); <LOGFILE>; $curpos = tell(LOGFILE)) {
        # process $_ here
    }
    sleep $naptime;
    seek(LOGFILE, $curpos, 0);  # seek to where we had been
}
#-----------------------------
exit if (stat(LOGFILE))[3] == 0
#-----------------------------
use File::stat;
exit if stat(*LOGFILE)->nlink == 0;
#-----------------------------

