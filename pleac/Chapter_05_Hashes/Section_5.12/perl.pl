
#-----------------------------
use Tie::RefHash;
tie %hash, "Tie::RefHash";
# you may now use references as the keys to %hash
#-----------------------------
# Class::Somewhere=HASH(0x72048)
# 
# ARRAY(0x72048)
#-----------------------------
use Tie::RefHash;
use IO::File;

tie %name, "Tie::RefHash";
foreach $filename ("/etc/termcap", "/vmunix", "/bin/cat") {
    $fh = IO::File->new("< $filename") or next;
    $name{$fh} = $filename;
}
print "open files: ", join(", ", values %name), "\n";
foreach $file (keys %name) {
    seek($file, 0, 2);      # seek to the end
    printf("%s is %d bytes long.\n", $name{$file}, tell($file));
}
#-----------------------------

