
#-----------------------------
package Alpha;
$name = "first";

package Omega;
$name = "last";

package main;
print "Alpha is $Alpha::name, Omega is $Omega::name.\n";
Alpha is first, Omega is last.
#-----------------------------
require "FileHandle.pm";            # run-time load
require FileHandle;                 # ".pm" assumed; same as previous
use FileHandle;                     # compile-time load

require "Cards/Poker.pm";           # run-time load
require Cards::Poker;               # ".pm" assumed; same as previous
use Cards::Poker;                   # compile-time load
#-----------------------------
1    package Cards::Poker;
2    use Exporter;
3    @ISA = ('Exporter');
4    @EXPORT = qw(&shuffle @card_deck);
5    @card_deck = ();                       # initialize package global
6    sub shuffle { }                        # fill-in definition later
7    1;                                     # don't forget this
#-----------------------------

