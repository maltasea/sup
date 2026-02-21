
#-----------------------------
binmode(HANDLE);
#-----------------------------
$gifname = "picture.gif";
open(GIF, $gifname)         or die "can't open $gifname: $!";

binmode(GIF);               # now DOS won't mangle binary input from GIF
binmode(STDOUT);            # now DOS won't mangle binary output to STDOUT

while (read(GIF, $buff, 8 * 2**10)) {
    print STDOUT $buff;
}
#-----------------------------

