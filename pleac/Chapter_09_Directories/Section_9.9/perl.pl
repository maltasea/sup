
#-----------------------------
foreach $file (@NAMES) {
    my $newname = $file;
    # change $newname
    rename($file, $newname) or  
        warn "Couldn't rename $file to $newname: $!\n";
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch09/rename
#-----------------------------
#% rename 's/\.orig$//'  *.orig
#% rename 'tr/A-Z/a-z/ unless /^Make/'  *
#% rename '$_ .= ".bad"'  *.f
#% rename 'print "$_: "; s/foo/bar/ if <STDIN> =~ /^y/i'  *
#% find /tmp -name '*~' -print | rename 's/^(.+)~$/.#$1/'
#-----------------------------
#% rename 'use locale; $_ = lc($_) unless /^Make/' *
#-----------------------------

