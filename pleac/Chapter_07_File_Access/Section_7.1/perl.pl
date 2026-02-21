
#-----------------------------
open(SOURCE, "< $path")
    or die "Couldn't open $path for reading: $!\n";

open(SINK, "> $path")
    or die "Couldn't open $path for writing: $!\n";
#-----------------------------
use Fcntl;

sysopen(SOURCE, $path, O_RDONLY)
    or die "Couldn't open $path for reading: $!\n";

sysopen(SINK, $path, O_WRONLY)
    or die "Couldn't open $path for writing: $!\n";
#-----------------------------
use IO::File;

# like Perl's open
$fh = IO::File->new("> $filename")
    or die "Couldn't open $filename for writing: $!\n";

# like Perl's sysopen
$fh = IO::File->new($filename, O_WRONLY|O_CREAT)
    or die "Couldn't open $filename for writing: $!\n";

# like stdio's fopen(3)
$fh = IO::File->new($filename, "r+")
    or die "Couldn't open $filename for read and write: $!\n";
#-----------------------------
sysopen(FILEHANDLE, $name, $flags)         or die "Can't open $name : $!";
sysopen(FILEHANDLE, $name, $flags, $perms) or die "Can't open $name : $!";
#-----------------------------
open(FH, "< $path")                                 or die $!;
sysopen(FH, $path, O_RDONLY)                        or die $!;
#-----------------------------
open(FH, "> $path")                                 or die $!;
sysopen(FH, $path, O_WRONLY|O_TRUNC|O_CREAT)        or die $!;
sysopen(FH, $path, O_WRONLY|O_TRUNC|O_CREAT, 0600)  or die $!;
#-----------------------------
sysopen(FH, $path, O_WRONLY|O_EXCL|O_CREAT)         or die $!;
sysopen(FH, $path, O_WRONLY|O_EXCL|O_CREAT, 0600)   or die $!;
#-----------------------------
open(FH, ">> $path")                                or die $!;
sysopen(FH, $path, O_WRONLY|O_APPEND|O_CREAT)       or die $!;
sysopen(FH, $path, O_WRONLY|O_APPEND|O_CREAT, 0600) or die $!;
#-----------------------------
sysopen(FH, $path, O_WRONLY|O_APPEND)               or die $!;
#-----------------------------
open(FH, "+< $path")                                or die $!;
sysopen(FH, $path, O_RDWR)                          or die $!;
#-----------------------------
sysopen(FH, $path, O_RDWR|O_CREAT)                  or die $!;
sysopen(FH, $path, O_RDWR|O_CREAT, 0600)            or die $!;
#-----------------------------
sysopen(FH, $path, O_RDWR|O_EXCL|O_CREAT)           or die $!;
sysopen(FH, $path, O_RDWR|O_EXCL|O_CREAT, 0600)     or die $!;
#-----------------------------

