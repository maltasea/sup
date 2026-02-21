
#-----------------------------
while (defined ($line = <DATAFILE>)) {
    chomp $line;
    $size = length $line;
    print "$size\n";                # output size of line
}
#-----------------------------
while (<DATAFILE>) {
    chomp;
    print length, "\n";             # output size of line
}
#-----------------------------
@lines = <DATAFILE>;
#-----------------------------
undef $/;
$whole_file = <FILE>;               # 'slurp' mode
#-----------------------------
#% perl -040 -e '$word = <>; print "First word is $word\n";'
#-----------------------------
#% perl -ne 'BEGIN { $/="%%\n" } chomp; print if /Unix/i' fortune.dat
#-----------------------------
print HANDLE "One", "two", "three"; # "Onetwothree"
print "Baa baa black sheep.\n";     # Sent to default output handle
#-----------------------------
$rv = read(HANDLE, $buffer, 4096)
        or die "Couldn't read from HANDLE : $!\n";
# $rv is the number of bytes read,
# $buffer holds the data read
#-----------------------------
truncate(HANDLE, $length)
    or die "Couldn't truncate: $!\n";
truncate("/tmp/$$.pid", $length)
    or die "Couldn't truncate: $!\n";
#-----------------------------
$pos = tell(DATAFILE);
print "I'm $pos bytes from the start of DATAFILE.\n";
#-----------------------------
seek(LOGFILE, 0, 2)         or die "Couldn't seek to the end: $!\n";
seek(DATAFILE, $pos, 0)     or die "Couldn't seek to $pos: $!\n";
seek(OUT, -20, 1)           or die "Couldn't seek back 20 bytes: $!\n";
#-----------------------------
$written = syswrite(DATAFILE, $mystring, length($mystring));
die "syswrite failed: $!\n" unless $written == length($mystring);
$read = sysread(INFILE, $block, 256, 5);
warn "only read $read bytes, not 256" if 256 != $read;
#-----------------------------
$pos = sysseek(HANDLE, 0, 1);       # don't change position
die "Couldn't sysseek: $!\n" unless defined $pos;
#-----------------------------

