
#-----------------------------
#% perl -e 'for (@INC) { printf "%d %s\n", $i++, $_ }'
#0 /usr/local/perl/lib/i686-linux/5.004
#
#1 /usr/local/perl/lib
#
#2 /usr/local/perl/lib/site_perl/i686-linux
#
#3 /usr/local/perl/lib/site_perl
#
#4 .
#-----------------------------
# syntax for sh, bash, ksh, or zsh
#$ export PERL5LIB=$HOME/perllib

# syntax for csh or tcsh
#% setenv PERL5LIB ~/perllib
#-----------------------------
use lib "/projects/spectre/lib";
#-----------------------------
use FindBin;
use lib $FindBin::Bin;
#-----------------------------
use FindBin qw($Bin);
use lib "$Bin/../lib";
#-----------------------------

