
#-----------------------------
use File::Basename;

$base = basename($path);
$dir  = dirname($path);
($base, $dir, $ext) = fileparse($path);
#-----------------------------
$path = '/usr/lib/libc.a';
$file = basename($path);    
$dir  = dirname($path);     

print "dir is $dir, file is $file\n";
# dir is /usr/lib, file is libc.a
#-----------------------------
$path = '/usr/lib/libc.a';
($name,$dir,$ext) = fileparse($path,'\..*');

print "dir is $dir, name is $name, extension is $ext\n";
# dir is /usr/lib/, name is libc, extension is .a
#-----------------------------
fileparse_set_fstype("MacOS");
$path = "Hard%20Drive:System%20Folder:README.txt";
($name,$dir,$ext) = fileparse($path,'\..*');

print "dir is $dir, name is $name, extension is $ext\n";
# dir is Hard%20Drive:System%20Folder, name is README, extension is .txt
#-----------------------------
sub extension {
    my $path = shift;
    my $ext = (fileparse($path,'\..*'))[2];
    $ext =~ s/^\.//;
    return $ext;
}
#-----------------------------

