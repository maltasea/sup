
#-----------------------------
($DAY, $MONTH, $YEAR) = (localtime)[3,4,5];
#-----------------------------
use Time::localtime;
$tm = localtime;
($DAY, $MONTH, $YEAR) = ($tm->mday, $tm->mon, $tm->year);
#-----------------------------
($day, $month, $year) = (localtime)[3,4,5];
printf("The current date is %04d %02d %02d\n", $year+1900, $month+1, $day);
# The current date is 1998 04 28
#-----------------------------
($day, $month, $year) = (localtime)[3..5];
#-----------------------------
use Time::localtime;
$tm = localtime;
printf("The current date is %04d-%02d-%02d\n", $tm->year+1900, 
    ($tm->mon)+1, $tm->mday);
# The current date is 1998-04-28
#-----------------------------
printf("The current date is %04d-%02d-%02d\n",
       sub {($_[5]+1900, $_[4]+1, $_[3])}->(localtime));
#-----------------------------
use POSIX qw(strftime);
print strftime "%Y-%m-%d\n", localtime;
#-----------------------------

