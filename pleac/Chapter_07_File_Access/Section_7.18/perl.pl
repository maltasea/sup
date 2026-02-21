
#-----------------------------
foreach $filehandle (@FILEHANDLES) {
    print $filehandle $stuff_to_print;
}
#-----------------------------
open(MANY, "| tee file1 file2 file3 > /dev/null")   or die $!;
print MANY "data\n"                                 or die $!;
close(MANY)                                         or die $!;
#-----------------------------
# `use strict' complains about this one:
for $fh ('FH1', 'FH2', 'FH3')   { print $fh "whatever\n" }
# but not this one:
for $fh (*FH1, *FH2, *FH3)      { print $fh "whatever\n" }
#-----------------------------
open (FH, "| tee file1 file2 file3 >/dev/null");
print FH "whatever\n";
#-----------------------------
# make STDOUT go to three files, plus original STDOUT
open (STDOUT, "| tee file1 file2 file3") or die "Teeing off: $!\n";
print "whatever\n"                       or die "Writing: $!\n";
close(STDOUT)                            or die "Closing: $!\n";
#-----------------------------

