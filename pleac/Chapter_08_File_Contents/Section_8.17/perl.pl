
#-----------------------------
( $dev, $ino, $mode, $nlink, 
  $uid, $gid, $rdev, $size, 
  $atime, $mtime, $ctime, 
  $blksize, $blocks )       = stat($filename)
        or die "no $filename: $!";

$mode &= 07777;             # discard file type info
#-----------------------------
$info = stat($filename)     or die "no $filename: $!";
if ($info->uid == 0) {
    print "Superuser owns $filename\n";
} 
if ($info->atime > $info->mtime) {
    print "$filename has been read since it was written.\n";
} 
#-----------------------------
use File::stat;

sub is_safe {
    my $path = shift;
    my $info = stat($path);
    return unless $info;

    # owner neither superuser nor me 
    # the real uid is in stored in the $< variable
    if (($info->uid != 0) && ($info->uid != $<)) {
        return 0;
    }

    # check whether group or other can write file.
    # use 066 to detect either reading or writing
    if ($info->mode & 022) {   # someone else can write this
        return 0 unless -d _;  # non-directories aren't safe
            # but directories with the sticky bit (01000) are
        return 0 unless $info->mode & 01000;        
    }
    return 1;
}
#-----------------------------
use Cwd;
use POSIX qw(sysconf _PC_CHOWN_RESTRICTED);
sub is_verysafe {
    my $path = shift;
    return is_safe($path) if sysconf(_PC_CHOWN_RESTRICTED);
    $path = getcwd() . '/' . $path if $path !~ m{^/};
    do {
        return unless is_safe($path);
        $path =~ s#([^/]+|/)$##;               # dirname
        $path =~ s#/$## if length($path) > 1;  # last slash
    } while length $path;

    return 1;
}
#-----------------------------
$file = "$ENV{HOME}/.myprogrc";
readconfig($file) if is_safe($file);
#-----------------------------
$file = "$ENV{HOME}/.myprogrc";
if (open(FILE, "< $file")) { 
    readconfig(*FILE) if is_safe(*FILE);
}
#-----------------------------

