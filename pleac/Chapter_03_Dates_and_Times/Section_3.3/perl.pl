
#-----------------------------
($seconds, $minutes, $hours, $day_of_month, $month, $year,
    $wday, $yday, $isdst) = localtime($time);
#-----------------------------
use Time::localtime;        # or Time::gmtime
$tm = localtime($TIME);     # or gmtime($TIME)
$seconds = $tm->sec;
# ...
#-----------------------------
($seconds, $minutes, $hours, $day_of_month, $month, $year,
    $wday, $yday, $isdst) = localtime($time);
printf("Dateline: %02d:%02d:%02d-%04d/%02d/%02d\n",
    $hours, $minutes, $seconds, $year+1900, $month+1,
    $day_of_month);
#-----------------------------
use Time::localtime;
$tm = localtime($time);
printf("Dateline: %02d:%02d:%02d-%04d/%02d/%02d\n",
    $tm->hour, $tm->min, $tm->sec, $tm->year+1900,
    $tm->mon+1, $tm->mday);
#-----------------------------

