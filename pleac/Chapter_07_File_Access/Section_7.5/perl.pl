
#-----------------------------
use IO::File;

$fh = IO::File->new_tmpfile
        or die "Unable to make new temporary file: $!";
#-----------------------------
use IO::File;
use POSIX qw(tmpnam);

# try new temporary filenames until we get one that didn't already exist
do { $name = tmpnam() }
    until $fh = IO::File->new($name, O_RDWR|O_CREAT|O_EXCL);

# install atexit-style handler so that when we exit or die,
# we automatically delete this temporary file
END { unlink($name) or die "Couldn't unlink $name : $!" }

# now go on to use the file ...
#-----------------------------
for (;;) {
    $name = tmpnam();
    sysopen(TMP, $tmpnam, O_RDWR | O_CREAT | O_EXCL) && last;
}
unlink $tmpnam;
#-----------------------------
use IO::File;

$fh = IO::File->new_tmpfile             or die "IO::File->new_tmpfile: $!";
$fh->autoflush(1);
print $fh "$i\n" while $i++ < 10;
seek($fh, 0, 0)                         or die "seek: $!";
print "Tmp file has: ", <$fh>;
#-----------------------------

