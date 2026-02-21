
#-----------------------------
$when = $now + $difference;
$then = $now - $difference;
#-----------------------------
use Date::Calc qw(Add_Delta_Days);
($y2, $m2, $d2) = Add_Delta_Days($y, $m, $d, $offset);
#-----------------------------
use Date::Calc qw(Add_Delta_DHMS);
($year2, $month2, $day2, $h2, $m2, $s2) = 
    Add_Delta_DHMS( $year, $month, $day, $hour, $minute, $second,
                $days_offset, $hour_offset, $minute_offset, $second_offset );
#-----------------------------
$birthtime = 96176750;                  # 18/Jan/1973, 3:45:50 am
$interval = 5 +                         # 5 seconds
            17 * 60 +                   # 17 minutes
            2  * 60 * 60 +              # 2 hours
            55 * 60 * 60 * 24;          # and 55 days
$then = $birthtime + $interval;
print "Then is ", scalar(localtime($then)), "\n";
# Then is Wed Mar 14 06:02:55 1973
#-----------------------------
use Date::Calc qw(Add_Delta_DHMS);
($year, $month, $day, $hh, $mm, $ss) = Add_Delta_DHMS(
    1973, 1, 18, 3, 45, 50, # 18/Jan/1973, 3:45:50 am
             55, 2, 17, 5); # 55 days, 2 hrs, 17 min, 5 sec
print "To be precise: $hh:$mm:$ss, $month/$day/$year\n";
# To be precise: 6:2:55, 3/14/1973
#-----------------------------
use Date::Calc qw(Add_Delta_Days);
($year, $month, $day) = Add_Delta_Days(1973, 1, 18, 55);
print "Nat was 55 days old on: $month/$day/$year\n";
# Nat was 55 days old on: 3/14/1973
#-----------------------------

