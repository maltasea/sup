
#-----------------------------
select(undef, undef, undef, $time_to_sleep);
#-----------------------------
use Time::HiRes qw(sleep);
sleep($time_to_sleep);
#-----------------------------
while (<>) {
    select(undef, undef, undef, 0.25);
    print;
}
#-----------------------------
use Time::HiRes qw(sleep);
while (<>) {
    sleep(0.25);
    print;
}
#-----------------------------

