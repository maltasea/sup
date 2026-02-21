
#-----------------------------
@entry = stat("/usr/bin/vi") or die "Couldn't stat /usr/bin/vi : $!";
#-----------------------------
@entry = stat("/usr/bin")    or die "Couldn't stat /usr/bin : $!";
#-----------------------------
@entry = stat(INFILE)        or die "Couldn't stat INFILE : $!";
#-----------------------------
use File::stat;

$inode = stat("/usr/bin/vi");
$ctime = $inode->ctime;
$size  = $inode->size;
#-----------------------------
open( F, "< $filename" )
    or die "Opening $filename: $!\n";
unless (-s F && -T _) {
    die "$filename doesn't have text in it.\n";
}
#-----------------------------
opendir(DIRHANDLE, "/usr/bin") or die "couldn't open /usr/bin : $!";
while ( defined ($filename = readdir(DIRHANDLE)) ) {
    print "Inside /usr/bin is something called $filename\n";
}
closedir(DIRHANDLE);
#-----------------------------

