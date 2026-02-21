
#-----------------------------
$seconds = $recent - $earlier;
#-----------------------------
use Date::Calc qw(Delta_Days);
$days = Delta_Days( $year1, $month1, $day1, $year2, $month2, $day2);
#-----------------------------
use Date::Calc qw(Delta_DHMS);
($days, $hours, $minutes, $seconds) =
  Delta_DHMS( $year1, $month1, $day1, $hour1, $minute1, $seconds1,  # earlier
              $year2, $month2, $day2, $hour2, $minute2, $seconds2); # later
#-----------------------------
$bree = 361535725;          # 16 Jun 1981, 4:35:25
$nat  =  96201950;          # 18 Jan 1973, 3:45:50

$difference = $bree - $nat;
print "There were $difference seconds between Nat and Bree\n";
# There were 265333775 seconds between Nat and Bree


$seconds    =  $difference % 60;
$difference = ($difference - $seconds) / 60;
$minutes    =  $difference % 60;
$difference = ($difference - $minutes) / 60;
$hours      =  $difference % 24;
$difference = ($difference - $hours)   / 24;
$days       =  $difference % 7;
$weeks      = ($difference - $days)    /  7;

print "($weeks weeks, $days days, $hours:$minutes:$seconds)\n";
# (438 weeks, 4 days, 23:49:35)
#-----------------------------
use Date::Calc qw(Delta_Days);
@bree = (1981, 6, 16);      # 16 Jun 1981
@nat  = (1973, 1, 18);      # 18 Jan 1973
$difference = Delta_Days(@nat, @bree);
print "There were $difference days between Nat and Bree\n";
# There were 3071 days between Nat and Bree
#-----------------------------
use Date::Calc qw(Delta_DHMS);
@bree = (1981, 6, 16, 4, 35, 25);   # 16 Jun 1981, 4:35:25
@nat  = (1973, 1, 18, 3, 45, 50);   # 18 Jan 1973, 3:45:50
@diff = Delta_DHMS(@nat, @bree);
print "Bree came $diff[0] days, $diff[1]:$diff[2]:$diff[3] after Nat\n";
# Bree came 3071 days, 0:49:35 after Nat
#-----------------------------

