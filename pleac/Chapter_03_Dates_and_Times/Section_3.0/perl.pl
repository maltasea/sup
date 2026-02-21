
#-----------------------------
$sec
#-----------------------------
$min
#-----------------------------
$hours
#-----------------------------
$mday
#-----------------------------
$month
#-----------------------------
$year
#-----------------------------
$wday
#-----------------------------
$yday
#-----------------------------
$isdst
#-----------------------------
#Fri Apr 11 09:27:08 1997
#-----------------------------
# using arrays
print "Today is day ", (localtime)[7], " of the current year.\n";
# Today is day 117 of the current year.

# using Time::tm objects
use Time::localtime;
$tm = localtime;
print "Today is day ", $tm->yday, " of the current year.\n";
# Today is day 117 of the current year.
#-----------------------------

