
#-----------------------------
@list = <*.c>;
@list = glob("*.c");
#-----------------------------
opendir(DIR, $path);
@files = grep { /\.c$/ } readdir(DIR);
closedir(DIR);
#-----------------------------
use File::KGlob;

@files = glob("*.c");
#-----------------------------
@files = grep { /\.[ch]$/i } readdir(DH);
#-----------------------------
use DirHandle;

$dh = DirHandle->new($path)   or die "Can't open $path : $!\n";
@files = grep { /\.[ch]$/i } $dh->read();
#-----------------------------
opendir(DH, $dir)        or die "Couldn't open $dir for reading: $!";

@files = ();
while( defined ($file = readdir(DH)) ) {
    next unless /\.[ch]$/i;

    my $filename = "$dir/$file";
    push(@files, $filename) if -T $file;
}
#-----------------------------
@dirs = map  { $_->[1] }                # extract pathnames
        sort { $a->[0] <=> $b->[0] }    # sort names numeric
        grep { -d $_->[1] }             # path is a dir
        map  { [ $_, "$path/$_" ] }     # form (name, path)
        grep { /^\d+$/ }                # just numerics
        readdir(DIR);                   # all files
#-----------------------------

