
#-----------------------------
#Can't locate sys/syscall.ph in @INC (did you run h2ph?)
#
#(@INC contains: /usr/lib/perl5/i686-linux/5.00404 /usr/lib/perl5
#
#/usr/lib/perl5/site_perl/i686-linux /usr/lib/perl5/site_perl .)
#
#at some_program line 7.
#-----------------------------
#% cd /usr/include; h2ph sys/syscall.h
#-----------------------------
#% cd /usr/include; h2ph *.h */*.h
#-----------------------------
#% cd /usr/include; find . -name '*.h' -print | xargs h2ph
#-----------------------------
# file FineTime.pm
package main;
require 'sys/syscall.ph';
die "No SYS_gettimeofday in sys/syscall.ph"
    unless defined &SYS_gettimeofday;

package FineTime;
    use strict;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(time);

sub time() {
    my $tv = pack("LL", ());  # presize buffer to two longs
    syscall(&main::SYS_gettimeofday, $tv, undef) >= 0
        or die "gettimeofday: $!";
    my($seconds, $microseconds) = unpack("LL", $tv);
    return $seconds + ($microseconds / 1_000_000);
}

1;
#-----------------------------
# ^^INCLUDE^^ include/perl/ch12/jam
#-----------------------------
#% cat > tio.c <<EOF && cc tio.c && a.out
##include <sys/ioctl.h>
#main() { printf("%#08x\n", TIOCSTI); }
#EOF
#0x005412
#-----------------------------
# ^^INCLUDE^^ include/perl/ch12/winsz
#-----------------------------

