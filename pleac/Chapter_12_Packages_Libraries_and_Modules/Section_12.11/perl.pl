
#-----------------------------
package FineTime;
use strict;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(time);

sub time() { ..... }  # TBA
#-----------------------------
use FineTime qw(time);
$start = time();
1 while print time() - $start, "\n";
#-----------------------------

