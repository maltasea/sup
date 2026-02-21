
#-----------------------------
package Alpha;
my $aa = 10;
   $x = "azure";

package Beta;
my $bb = 20;
   $x = "blue";

package main;
print "$aa, $bb, $x, $Alpha::x, $Beta::x\n";
10, 20, , azure, blue
#-----------------------------
# Flipper.pm
package Flipper;
use strict;

require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA     = qw(Exporter);
@EXPORT  = qw(flip_words flip_boundary);
$VERSION = 1.0;

my $Separatrix = ' ';  # default to blank; must precede functions

sub flip_boundary {
    my $prev_sep = $Separatrix;
    if (@_) { $Separatrix = $_[0] }
    return $prev_sep;
}
sub flip_words {
    my $line  = $_[0];
    my @words = split($Separatrix, $line);
    return join($Separatrix, reverse @words);
}
1;
#-----------------------------

