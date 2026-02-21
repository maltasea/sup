
#-----------------------------
$status = system("vi $myfile");
#-----------------------------
$status = system("vi", $myfile);
#-----------------------------
system("cmd1 args | cmd2 | cmd3 >outfile");
system("cmd args <infile >outfile 2>errfile");
#-----------------------------
$status = system($program, $arg1, $arg);
die "$program exited funny: $?" unless $status == 0;
#-----------------------------
if (($signo = system(@arglist)) &= 127) { 
    die "program killed by signal $signo\n";
}
#-----------------------------
if ($pid = fork) {
    # parent catches INT and berates user
    local $SIG{INT} = sub { print "Tsk tsk, no process interruptus\n" };
    waitpid($pid, 0);
} else {
    die "cannot fork: $!" unless defined $pid;
    # child ignores INT and does its thing
    $SIG{INT} = "IGNORE";
    exec("summarize", "/etc/logfiles")             or die "Can't exec: $!\n";
}
#-----------------------------
$shell = '/bin/tcsh';
system $shell '-csh';           # pretend it's a login shell
#-----------------------------
system {'/bin/tcsh'} '-csh';    # pretend it's a login shell
#-----------------------------
# call expn as vrfy
system {'/home/tchrist/scripts/expn'} 'vrfy', @ADDRESSES;
#-----------------------------
@args = ( "echo surprise" );

system @args;               # subject to shell escapes if @args == 1
system { $args[0] } @args;  # safe even with one-arg list
#-----------------------------

