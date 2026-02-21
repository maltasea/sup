
#-----------------------------
use Time::Local;
# $date is "1998-06-03" (YYYY-MM-DD form).
($yyyy, $mm, $dd) = $date =~ /(\d+)-(\d+)-(\d+)/;
# calculate epoch seconds at midnight on that day in this timezone
$epoch_seconds = timelocal(0, 0, 0, $dd, $mm, $yyyy);
#-----------------------------
use Date::Manip qw(ParseDate UnixDate);
$date = ParseDate($string);
if (!$date) {
    # bad date
} else {
    @values = UnixDate($date, @formats);
}
#-----------------------------
use Date::Manip qw(ParseDate UnixDate);

while (<>) {
    $date = ParseDate($_);
    if (!$date) {
        warn "Bad date string: $_\n";
        next;
    } else {
        ($year, $month, $day) = UnixDate($date, "%Y", "%m", "%d");
        print "Date was $month/$day/$year\n";
    }
}
#-----------------------------

