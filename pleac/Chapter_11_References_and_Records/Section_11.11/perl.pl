
#-----------------------------
DB<1> $reference = [ { "foo" => "bar" }, 3, sub { print "hello, world\n" } ];
DB<2> x $reference
  0  ARRAY(0x1d033c)

    0  HASH(0x7b390)

       'foo' = 'bar'>

    1  3

    2  CODE(0x21e3e4)

       - & in ???>
#-----------------------------
use Data::Dumper;
print Dumper($reference);
#-----------------------------
D<1> x \@INC
  0  ARRAY(0x807d0a8)

     0  '/home/tchrist/perllib' 

     1  '/usr/lib/perl5/i686-linux/5.00403'

     2  '/usr/lib/perl5' 

     3  '/usr/lib/perl5/site_perl/i686-linux' 

     4  '/usr/lib/perl5/site_perl' 

     5  '.'
#-----------------------------
{ package main; require "dumpvar.pl" } 
*dumpvar = \&main::dumpvar if __PACKAGE__ ne 'main';
dumpvar("main", "INC");             # show both @INC and %INC
#-----------------------------
@INC = (

   0  '/home/tchrist/perllib/i686-linux'

   1  '/home/tchrist/perllib'

   2  '/usr/lib/perl5/i686-linux/5.00404'

   3  '/usr/lib/perl5'

   4  '/usr/lib/perl5/site_perl/i686-linux'

   5  '/usr/lib/perl5/site_perl'

   6  '.'

)

%INC = (

   'dumpvar.pl' = '/usr/lib/perl5/i686-linux/5.00404/dumpvar.pl'

   'strict.pm' = '/usr/lib/perl5/i686-linux/5.00404/strict.pm'

)
#-----------------------------
use Data::Dumper; 
print Dumper(\@INC); 
$VAR1 = [

      '/home/tchrist/perllib', 

      '/usr/lib/perl5/i686-linux/5.00403',

      '/usr/lib/perl5', 

      '/usr/lib/perl5/site_perl/i686-linux',

      '/usr/lib/perl5/site_perl', 

      '.'

];
#-----------------------------

