
#-----------------------------
$STRING = localtime($EPOCH_SECONDS);
#-----------------------------
use POSIX qw(strftime);
$STRING = strftime($FORMAT, $SECONDS, $MINUTES, $HOUR,
                   $DAY_OF_MONTH, $MONTH, $YEAR, $WEEKDAY,
                   $YEARDAY, $DST);
#-----------------------------
use Date::Manip qw(UnixDate);
$STRING = UnixDate($DATE, $FORMAT);
#-----------------------------
# Sun Sep 21 15:33:36 1997
#-----------------------------
use Time::Local;
$time = timelocal(50, 45, 3, 18, 0, 73);
print "Scalar localtime gives: ", scalar(localtime($time)), "\n";
# Scalar localtime gives: Thu Jan 18 03:45:50 1973
#-----------------------------
use POSIX qw(strftime);
use Time::Local;
$time = timelocal(50, 45, 3, 18, 0, 73);
print "strftime gives: ", strftime("%A %D", localtime($time)), "\n";
# strftime gives: Thursday 01/18/73
#-----------------------------
use Date::Manip qw(ParseDate UnixDate);
$date = ParseDate("18 Jan 1973, 3:45:50");
$datestr = UnixDate($date, "%a %b %e %H:%M:%S %z %Y");    # as scalar
print "Date::Manip gives: $datestr\n";
# Date::Manip gives: Thu Jan 18 03:45:50 GMT 1973
#-----------------------------

