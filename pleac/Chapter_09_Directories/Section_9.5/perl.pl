
#-----------------------------
opendir(DIR, $dirname) or die "can't opendir $dirname: $!";
while (defined($file = readdir(DIR))) {
    # do something with "$dirname/$file"
}
closedir(DIR);
#-----------------------------
$dir = "/usr/local/bin";
print "Text files in $dir are:\n";
opendir(BIN, $dir) or die "Can't open $dir: $!";
while( defined ($file = readdir BIN) ) {
    print "$file\n" if -T "$dir/$file";
}
closedir(BIN);
#-----------------------------
while ( defined ($file = readdir BIN) ) {
    next if $file =~ /^\.\.?$/;     # skip . and ..
    # ...
}
#-----------------------------
use DirHandle;

sub plainfiles {
   my $dir = shift;
   my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";
   return sort                     # sort pathnames
          grep {    -f     }       # choose only "plain" files
          map  { "$dir/$_" }       # create full paths
          grep {  !/^\./   }       # filter out dot files
          $dh->
read()
;             # read all entries
}
#-----------------------------

