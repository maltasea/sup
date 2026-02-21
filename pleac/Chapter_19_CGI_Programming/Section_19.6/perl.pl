
#-----------------------------
system("command $input @files");            # UNSAFE
#-----------------------------
system("command", $input, @files);          # safer
#-----------------------------
chomp($now = `date`);
#-----------------------------
@output = `grep $input @files`;
#-----------------------------
die "cannot fork: $!" unless defined ($pid = open(SAFE_KID, "|-"));
if ($pid == 0) {
    exec('grep', $input, @files) or die "can't exec grep: $!";
} else {
    @output = <SAFE_KID>;
    close SAFE_KID;                 # $? contains status
}
#-----------------------------
open(KID_TO_READ, "$program @options @args |");    # UNSAFE
#-----------------------------
# add error processing as above
die "cannot fork: $!" unless defined($pid = open(KID_TO_READ, "-|"));

if ($pid) {   # parent
   while (<KID_TO_READ>) {
       # do something interesting
   }
   close(KID_TO_READ)               or warn "kid exited $?";

} else {      # child
   # reconfigure, then
   exec($program, @options, @args)  or die "can't exec program: $!";
}
#-----------------------------
open(KID_TO_WRITE, "|$program $options @args");   # UNSAFE
#-----------------------------
$pid = open(KID_TO_WRITE, "|-");
die "cannot fork: $!" unless defined($pid = open(KID_TO_WRITE, "|-"));
$SIG{ALRM} = sub { die "whoops, $program pipe broke" };

if ($pid) {  # parent
   for (@data) { print KID_TO_WRITE $_ }
   close(KID_TO_WRITE)              or warn "kid exited $?";

} else {     # child
   # reconfigure, then
   exec($program, @options, @args)  or die "can't exec program: $!";
}
#-----------------------------

