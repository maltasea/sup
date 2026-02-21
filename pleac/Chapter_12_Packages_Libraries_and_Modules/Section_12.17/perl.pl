
#-----------------------------
#% gunzip Some-Module-4.54.tar.gz
#% tar xf Some-Module-4.54
#% cd Some-Module-4.54
#% perl Makefile.PL
#% make
#% make test
#% make install
#-----------------------------
#% gunzip MD5-1.7.tar.gz
#% tar xf MD5-1.7.tar
#% cd MD5-1.7
#% perl Makefile.PL 
#Checking if your kit is complete...
#
#Looks good
#
#Writing Makefile for MD5
#
#% make
#mkdir ./blib
#
#mkdir ./blib/lib
#
#cp MD5.pm ./blib/lib/MD5.pm
#
#AutoSplitting MD5 (./blib/lib/auto/MD5)
#
#/usr/bin/perl -I/usr/local/lib/perl5/i386 ...
#
#...
#
#cp MD5.bs ./blib/arch/auto/MD5/MD5.bs
#
#chmod 644 ./blib/arch/auto/MD5/MD5.bsmkdir ./blib/man3
#
#Manifying ./blib/man3/MD5.3
#
#% make test
#PERL_DL_NONLAZY=1 /usr/bin/perl -I./blib/arch -I./blib/lib
#
#-I/usr/local/lib/perl5/i386-freebsd/5.00404 -I/usr/local/lib/perl5 test.pl
#
#1..14
#
#ok 1
#
#ok 2
#
#...
#
#ok 13
#
#ok 14
#
#% sudo make install
#Password:
#
#Installing /usr/local/lib/perl5/site_perl/i386-freebsd/./auto/MD5/
#
#    MD5.so
#
#Installing /usr/local/lib/perl5/site_perl/i386-freebsd/./auto/MD5/
#
#    MD5.bs
#
#Installing /usr/local/lib/perl5/site_perl/./auto/MD5/autosplit.ix
#
#Installing /usr/local/lib/perl5/site_perl/./MD5.pm
#
#Installing /usr/local/lib/perl5/man/man3/./MD5.3
#
#Writing /usr/local/lib/perl5/site_perl/i386-freebsd/auto/MD5/.packlist
#
#Appending installation info to /usr/local/lib/perl5/i386-freebsd/
#
#5.00404/perllocal.pod
#-----------------------------
# if you just want the modules installed in your own directory
#% perl Makefile.PL LIB=~/lib
#
# if you have your own a complete distribution
#% perl Makefile.PL PREFIX=~/perl5-private
#-----------------------------

