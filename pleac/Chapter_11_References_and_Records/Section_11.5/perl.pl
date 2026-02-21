
#-----------------------------
$scalar_ref = \$scalar;       # get reference to named scalar
#-----------------------------
undef $anon_scalar_ref;
$$anon_scalar_ref = 15;
#-----------------------------
$anon_scalar_ref = \15;
#-----------------------------
print ${ $scalar_ref };       # dereference it
${ $scalar_ref } .= "string"; # alter referent's value
#-----------------------------
sub new_anon_scalar {
    my $temp;
    return \$temp;
}
#-----------------------------
$sref = new_anon_scalar();
$$sref = 3;
print "Three = $$sref\n";
@array_of_srefs = ( new_anon_scalar(), new_anon_scalar() );
${ $array[0] } = 6.02e23;
${ $array[1] } = "avocado";
print "\@array contains: ", join(", ", map { $$_ } @array ), "\n";
#-----------------------------
$var        = `uptime`;     # $var holds text
$vref       = \$var;        # $vref "points to" $var
if ($$vref =~ /load/) {}    # look at $var, indirectly
chomp $$vref;               # alter $var, indirectly
#-----------------------------
# check whether $someref contains a simple scalar reference
if (ref($someref) ne 'SCALAR') {
    die "Expected a scalar reference, not $someref\n";

}
#-----------------------------

