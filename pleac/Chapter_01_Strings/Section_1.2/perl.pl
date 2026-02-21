
#-----------------------------
# use $b if $b is true, else $c
$a = $b || $c;              

# set $x to $y unless $x is already true
$x ||= $y
#-----------------------------
# use $b if $b is defined, else $c
$a = defined($b) ? $b : $c;
#-----------------------------
$foo = $bar || "DEFAULT VALUE";
#-----------------------------
$dir = shift(@ARGV) || "/tmp";
#-----------------------------
$dir = $ARGV[0] || "/tmp";
#-----------------------------
$dir = defined($ARGV[0]) ? shift(@ARGV) : "/tmp";
#-----------------------------
$dir = @ARGV ? $ARGV[0] : "/tmp";
#-----------------------------
$count{ $shell || "/bin/sh" }++;
#-----------------------------
# find the user name on Unix systems
$user = $ENV{USER}
     || $ENV{LOGNAME}
     || getlogin()
     || (getpwuid($<))[0]
     || "Unknown uid number $<";
#-----------------------------
$starting_point ||= "Greenwich";
#-----------------------------
@a = @b unless @a;          # copy only if empty
@a = @b ? @b : @c;          # assign @b if nonempty, else @c
#-----------------------------

