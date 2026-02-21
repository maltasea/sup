
#-----------------------------
$output = `cmd 2>&1`;                          # with backticks
# or
$pid = open(PH, "cmd 2>&1 |");                 # with an open pipe
while (<PH>) { }                               # plus a read
#-----------------------------
$output = `cmd 2>/dev/null`;                   # with backticks
# or
$pid = open(PH, "cmd 2>/dev/null |");          # with an open pipe
while (<PH>) { }                               # plus a read
#-----------------------------
$output = `cmd 2>&1 1>/dev/null`;              # with backticks
# or
$pid = open(PH, "cmd 2>&1 1>/dev/null |");     # with an open pipe
while (<PH>) { }                               # plus a read
#-----------------------------
$output = `cmd 3>&1 1>&2 2>&3 3>&-`;           # with backticks
# or
$pid = open(PH, "cmd 3>&1 1>&2 2>&3 3>&-|");   # with an open pipe
while (<PH>) { }                               # plus a read
#-----------------------------
system("program args 1>/tmp/program.stdout 2>/tmp/program.stderr");
#-----------------------------
$output = `cmd 3>&1 1>&2 2>&3 3>&-`;        
#-----------------------------
$fd3 = $fd1;
$fd1 = $fd2;
$fd2 = $fd3;
$fd3 = undef;
#-----------------------------
system("prog args 1>tmpfile 2>&1");
system("prog args 2>&1 1>tmpfile");
#-----------------------------
# system ("prog args 1>tmpfile 2>&1");
$fd1 = "tmpfile";        # change stdout destination first
$fd2 = $fd1;             # now point stderr there, too
#-----------------------------
# system("prog args 2>&1 1>tmpfile");
$fd2 = $fd1;             # stderr same destination as stdout
$fd1 = "tmpfile";        # but change stdout destination 
#-----------------------------

