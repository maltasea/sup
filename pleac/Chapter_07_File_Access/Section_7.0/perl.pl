
#-----------------------------
open(INPUT, "< /usr/local/widgets/data")
    or die "Couldn't open /usr/local/widgets/data for reading: $!\n";

while (<INPUT>) {
    print if /blue/;
}
close(INPUT);
#-----------------------------
$var = *STDIN;
mysub($var, *LOGFILE);
#-----------------------------
use IO::File;

$input = IO::File->new("< /usr/local/widgets/data")
    or die "Couldn't open /usr/local/widgets/data for reading: $!\n";

while (defined($line = $input->getline())) {
    chomp($line);
    STDOUT->print($line) if $line =~ /blue/;
}
$input->close();
#-----------------------------
while (<STDIN>) {                   # reads from STDIN
    unless (/\d/) {
        warn "No digit found.\n";   # writes to STDERR
    }
    print "Read: ", $_;             # writes to STDOUT
}
END { close(STDOUT)                 or die "couldn't close STDOUT: $!" }
#-----------------------------
open(LOGFILE, "> /tmp/log")     or die "Can't write /tmp/log: $!";
#-----------------------------
close(FH)           or die "FH didn't close: $!";
#-----------------------------
$old_fh = select(LOGFILE);                  # switch to LOGFILE for output
print "Countdown initiated ...\n";
select($old_fh);                            # return to original output
print "You have 30 seconds to reach minimum safety distance.\n";
#-----------------------------

