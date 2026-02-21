
#-----------------------------
$dst = $src;
$dst =~ s/this/that/;
#-----------------------------
($dst = $src) =~ s/this/that/;
#-----------------------------
# strip to basename
($progname = $0)        =~ s!^.*/!!;

# Make All Words Title-Cased
($capword  = $word)     =~ s/(\w+)/\u\L$1/g;

# /usr/man/man3/foo.1 changes to /usr/man/cat3/foo.1
($catpage  = $manpage)  =~ s/man(?=\d)/cat/;
#-----------------------------
@bindirs = qw( /usr/bin /bin /usr/local/bin );
for (@libdirs = @bindirs) { s/bin/lib/ }
print "@libdirs\n";
# /usr/lib /lib /usr/local/lib
#-----------------------------
($a =  $b) =~ s/x/y/g;      # copy $b and then change $a
 $a = ($b  =~ s/x/y/g);     # change $b, count goes in $a
#-----------------------------

