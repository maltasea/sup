
#-----------------------------
#% perl Makefile.PL
#% make
#-----------------------------
#% h2xs -cn FineTime
#-----------------------------
#% perl Makefile.PL
#-----------------------------
#'LIBS'      => [''],   # e.g., '-lm'
#-----------------------------
#'LIBS'      => ['-L/usr/redhat/lib -lrpm'],
#-----------------------------
#% perl Makefile.PL LIB=~/perllib
#-----------------------------
package FineTime;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(time);
$VERSION = '0.01';
bootstrap FineTime $VERSION;
1;
##-----------------------------
##include <unistd.h>
##include <sys/time.h>
##include "EXTERN.h"
##include "perl.h"
##include "XSUB.h"
#
#MODULE = FineTime           PACKAGE = FineTime
#
#double
#time()
#    CODE:
#        struct timeval tv;
#        gettimeofday(&tv,0);
#        RETVAL = tv.tv_sec + ((double) tv.tv_usec) / 1000000;
#    OUTPUT:
#        RETVAL
#-----------------------------
#% make install
#mkdir ./blib/lib/auto/FineTime
#cp FineTime.pm ./blib/lib/FineTime.pm
#/usr/local/bin/perl -I/usr/lib/perl5/i686-linux/5.00403  -I/usr/lib/perl5
#/usr/lib/perl5/ExtUtils/xsubpp -typemap 
#    /usr/lib/perl5/ExtUtils/typemap FineTime.xs
#FineTime.tc && mv FineTime.tc FineTime.ccc -c -Dbool=char -DHAS_BOOL 
#    -O2-DVERSION=\"0.01\" -DXS_VERSION=\"0.01\" -fpic 
#    -I/usr/lib/perl5/i686-linux/5.00403/CORE  
#FineTime.cRunning Mkbootstrap for FineTime ()
#chmod 644 FineTime.bs
#LD_RUN_PATH="" cc -o blib/arch/auto/FineTime/FineTime.so 
#    -shared -L/usr/local/lib FineTime.o
#chmod 755 blib/arch/auto/FineTime/FineTime.so
#cp FineTime.bs ./blib/arch/auto/FineTime/FineTime.bs
#chmod 644 blib/arch/auto/FineTime/FineTime.bs
#Installing /home/tchrist/perllib/i686-linux/./auto/FineTime/FineTime.so
#Installing /home/tchrist/perllib/i686-linux/./auto/FineTime/FineTime.bs
#Installing /home/tchrist/perllib/./FineTime.pm
#Writing /home/tchrist/perllib/i686-linux/auto/FineTime/.packlist
#Appending installation info to /home/tchrist/perllib/i686-linux/perllocal.pod
#-----------------------------
#% perl -I ~/perllib -MFineTime=time -le '1 while print time()' | head
#888177070.090978
#
#888177070.09132
#
#888177070.091389
#
#888177070.091453
#
#888177070.091515
#
#888177070.091577
#
#888177070.091639
#
#888177070.0917
#
#888177070.091763
#
#888177070.091864
#-----------------------------

