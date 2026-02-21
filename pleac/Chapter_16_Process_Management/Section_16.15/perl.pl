
#-----------------------------
$SIG{QUIT} = \&got_sig_quit;     # call &got_sig_quit for every SIGQUIT 
$SIG{PIPE} = 'got_sig_pipe';     # call main::got_sig_pipe for every SIGPIPE 
$SIG{INT}  = sub { $ouch++ };    # increment $ouch for every SIGINT
#-----------------------------
$SIG{INT} = 'IGNORE';            # ignore the signal INT
#-----------------------------
$SIG{STOP} = 'DEFAULT';          # restore default STOP signal handling
#-----------------------------

