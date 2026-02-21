
#-----------------------------
use Time::Local;
$TIME = timelocal($sec, $min, $hours, $mday, $mon, $year);
$TIME = timegm($sec, $min, $hours, $mday, $mon, $year);
#-----------------------------
# $hours, $minutes, and $seconds represent a time today,
# in the current time zone
use Time::Local;
$time = timelocal($seconds, $minutes, $hours, (localtime)[3,4,5]);
#-----------------------------
# $day is day in month (1-31)
# $month is month in year (1-12)
# $year is four-digit year e.g., 1967
# $hours, $minutes and $seconds represent UTC time 
use Time::Local;
$time = timegm($seconds, $minutes, $hours, $day, $month-1, $year-1900);
#-----------------------------

