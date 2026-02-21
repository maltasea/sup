
#-----------------------------
$filename =~ s#^(\s)#./$1#;
open(HANDLE, "< $filename\0")          or die "cannot open $filename : $!\n";
#-----------------------------
sysopen(HANDLE, $filename, O_RDONLY)   or die "cannot open $filename: $!\n";
#-----------------------------
$filename = shift @ARGV;
open(INPUT, $filename)               or die "Couldn't open $filename : $!\n";
#-----------------------------
open(OUTPUT, ">$filename")
    or die "Couldn't open $filename for writing: $!\n";
#-----------------------------
use Fcntl;                          # for file constants

sysopen(OUTPUT, $filename, O_WRONLY|O_TRUNC)
    or die "Can't open $filename for writing: $!\n";
#-----------------------------
$file =~ s#^(\s)#./$1#;
open(OUTPUT, "> $file\0")
        or die "Couldn't open $file for OUTPUT : $!\n";
#-----------------------------

