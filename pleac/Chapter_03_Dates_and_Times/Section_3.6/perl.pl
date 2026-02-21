
#-----------------------------
($MONTHDAY, $WEEKDAY, $YEARDAY) = (localtime $DATE)[3,6,7];
$WEEKNUM = int($YEARDAY / 7) + 1;
#-----------------------------
use Date::Calc qw(Day_of_Week Week_Number Day_of_Year);
# you have $year, $month, and $day
# $day is day of month, by definition.
$wday = Day_of_Week($year, $month, $day);
$wnum = Week_Number($year, $month, $day);
$dnum = Day_of_Year($year, $month, $day);
#-----------------------------
use Date::Calc qw(Day_of_Week Week_Number Day_of_Week_to_Text)

$year  = 1981;
$month = 6;         # (June)
$day   = 16;

$wday = Day_of_Week($year, $month, $day);
print "$month/$day/$year was a ", Day_of_Week_to_Text($wday), "\n";
## see comment above

$wnum = Week_Number($year, $month, $day);
print "in the $wnum week.\n";
# 6/16/1981 was a Tuesday
# 
# in week number 25.
#-----------------------------

