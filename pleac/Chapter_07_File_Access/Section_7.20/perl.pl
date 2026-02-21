
#-----------------------------
*ALIAS = *ORIGINAL;
#-----------------------------
open(OUTCOPY, ">&STDOUT")   or die "Couldn't dup STDOUT: $!";
open(INCOPY,  "<&STDIN" )   or die "Couldn't dup STDIN : $!";
#-----------------------------
open(OUTALIAS, ">&=STDOUT") or die "Couldn't alias STDOUT: $!";
open(INALIAS,  "<&=STDIN")  or die "Couldn't alias STDIN : $!";
open(BYNUMBER, ">&=5")      or die "Couldn't alias file descriptor 5: $!";
#-----------------------------
# take copies of the file descriptors
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");

# redirect stdout and stderr
open(STDOUT, "> /tmp/program.out")  or die "Can't redirect stdout: $!";
open(STDERR, ">&STDOUT")            or die "Can't dup stdout: $!";

# run the program
system($joe_random_program);

# close the redirected filehandles
close(STDOUT)                       or die "Can't close STDOUT: $!";
close(STDERR)                       or die "Can't close STDERR: $!";

# restore stdout and stderr
open(STDERR, ">&OLDERR")            or die "Can't restore stderr: $!";
open(STDOUT, ">&OLDOUT")            or die "Can't restore stdout: $!";

# avoid leaks by closing the independent copies
close(OLDOUT)                       or die "Can't close OLDOUT: $!";
close(OLDERR)                       or die "Can't close OLDERR: $!";
#-----------------------------

