
#-----------------------------
use Time::HiRes qw(gettimeofday);
$t0 = gettimeofday;
## do your operation here
$t1 = gettimeofday;
$elapsed = $t1 - $t0;
# $elapsed is a floating point value, representing number
# of seconds between $t0 and $t1
#-----------------------------
use Time::HiRes qw(gettimeofday);
print "Press return when ready: ";
$before = gettimeofday;
$line = <>;
$elapsed = gettimeofday-$before;
print "You took $elapsed seconds.\n";
# Press return when ready: 
# 
# You took 0.228149 seconds.
#-----------------------------
require 'sys/syscall.ph';

# initialize the structures returned by gettimeofday
$TIMEVAL_T = "LL";
$done = $start = pack($TIMEVAL_T, ());

# prompt
print "Press return when ready: ";

# read the time into $start
syscall(&SYS_gettimeofday, $start, 0) != -1
           || die "gettimeofday: $!";

# read a line
$line = <>;

# read the time into $done
syscall(&SYS_gettimeofday, $done, 0) != -1
       || die "gettimeofday: $!";

# expand the structure
@start = unpack($TIMEVAL_T, $start);
@done  = unpack($TIMEVAL_T, $done);

# fix microseconds
for ($done[1], $start[1]) { $_ /= 1_000_000 }
    
# calculate time difference
$delta_time = sprintf "%.4f", ($done[0]  + $done[1]  )
                                         -
                              ($start[0] + $start[1] );

print "That took $delta_time seconds\n";
# Press return when ready: 
# 
# That took 0.3037 seconds
#-----------------------------
use Time::HiRes qw(gettimeofday);
# take mean sorting time
$size = 500;
$number_of_times = 100;
$total_time = 0;

for ($i = 0; $i < $number_of_times; $i++) {
    my (@array, $j, $begin, $time);
    # populate array
    @array = ();
    for ($j=0; $j<$size; $j++) { push(@array, rand) }

    # sort it
    $begin = gettimeofday;
    @array = sort { $a <=> $b } @array;
    $time = gettimeofday-$begin;
    $total_time += $time;
}

printf "On average, sorting %d random numbers takes %.5f seconds\n",
    $size, ($total_time/$number_of_times);
# On average, sorting 500 random numbers takes 0.02821 seconds
#-----------------------------

