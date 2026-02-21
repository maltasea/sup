
#-----------------------------
$this_pack = __PACKAGE__;
#-----------------------------
$that_pack = caller();
#-----------------------------
print "I am in package __PACKAGE__\n";              # WRONG!
I am in package __PACKAGE__
#-----------------------------
package Alpha;
runit('$line = <TEMP>');

package Beta;
sub runit {
    my $codestr = shift;
    eval $codestr;
    die if $@;
}
#-----------------------------
package Beta;
sub runit {
    my $codestr = shift;
    my $hispack = caller;
    eval "package $hispack; $codestr";
    die if $@;
}
#-----------------------------
package Alpha;
runit( sub { $line = <TEMP> } );

package Beta;
sub runit {
    my $coderef = shift;
    &$coderef();
}
#-----------------------------
open (FH, "< /etc/termcap")
    or die "can't open /etc/termcap: $!";
($a, $b, $c) = nreadline(3, 'FH');

use Symbol ();
use Carp;
sub nreadline {
    my ($count, $handle) = @_;
    my(@retlist,$line);

    croak "count must be > 0" unless $count > 0;
    $handle = Symbol::qualify($handle, (
caller()
)[0]);
    croak "need open filehandle" unless defined fileno($handle);

    push(@retlist, $line) while defined($line = <$handle>) && $count--;
    return @retlist;
}
#-----------------------------

