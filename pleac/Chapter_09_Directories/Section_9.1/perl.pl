
#-----------------------------
($READTIME, $WRITETIME) = (stat($filename))[8,9];

utime($NEWREADTIME, $NEWWRITETIME, $filename);
#-----------------------------
$SECONDS_PER_DAY = 60 * 60 * 24;
($atime, $mtime) = (stat($file))[8,9];
$atime -= 7 * $SECONDS_PER_DAY;
$mtime -= 7 * $SECONDS_PER_DAY;

utime($atime, $mtime, $file)
    or die "couldn't backdate $file by a week w/ utime: $!";
#-----------------------------
$mtime = (stat $file)[9];
utime(time, $mtime, $file);
#-----------------------------
use File::stat;
utime(time, stat($file)->mtime, $file);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch09/uvi
#-----------------------------

