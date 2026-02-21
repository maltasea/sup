
#-----------------------------
#% h2xs -XA -n Planets
#% h2xs -XA -n Astronomy::Orbits
#-----------------------------
package Astronomy::Orbits;
#-----------------------------
require Exporter;
require AutoLoader;
@ISA = qw(Exporter AutoLoader);
#-----------------------------
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
#-----------------------------
#% make dist
#-----------------------------

