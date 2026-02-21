
#-----------------------------
unlink($FILENAME)                 or die "Can't delete $FILENAME: $!\n";
unlink(@FILENAMES) == @FILENAMES  or die "Couldn't unlink all of @FILENAMES: $!\n";
#-----------------------------
unlink($file) or die "Can't unlink $file: $!";
#-----------------------------
unless (($count = unlink(@filelist)) == @filelist) {
    warn "could only delete $count of "
            . (@filelist) . " files";
}
#-----------------------------

