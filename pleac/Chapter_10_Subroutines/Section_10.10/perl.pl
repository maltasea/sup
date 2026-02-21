
#-----------------------------
return;
#-----------------------------
sub empty_retval {
    return ( wantarray ? () : undef );
}
#-----------------------------
if (@a = yourfunc()) { ... }
#-----------------------------
unless ($a = sfunc()) { die "sfunc failed" }
unless (@a = afunc()) { die "afunc failed" }
unless (%a = hfunc()) { die "hfunc failed" }
#-----------------------------
ioctl(....) or die "can't ioctl: $!";
#-----------------------------

