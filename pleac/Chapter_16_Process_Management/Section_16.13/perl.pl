
#-----------------------------
#% kill -l
#HUP INT QUIT ILL TRAP ABRT BUS FPE KILL USR1 SEGV USR2 PIPE 
#
#ALRM TERM CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM 
#
#PROF WINCH POLL PWR
#-----------------------------
#% perl -e 'print join(" ", keys %SIG), "\n"'
#XCPU ILL QUIT STOP EMT ABRT BUS USR1 XFSZ TSTP INT IOT USR2 INFO TTOU
#
#ALRM KILL HUP URG PIPE CONT SEGV VTALRM PROF TRAP IO TERM WINCH CHLD
#
#FPE TTIN SYS
#-----------------------------
#% perl -MConfig -e 'print $Config{sig_name}'
#ZERO HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM
#
#TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH
#
#INFO USR1 USR2 IOT
#-----------------------------
use Config;
defined $Config{sig_name} or die "No sigs?";
$i = 0;                     # Config prepends fake 0 signal called "ZERO".
foreach $name (split(' ', $Config{sig_name})) {
    $signo{$name} = $i;
    $signame[$i] = $name;
    $i++;
}
#-----------------------------

