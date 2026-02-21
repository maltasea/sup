
#-----------------------------
{
    no strict 'refs';
    $val  = ${ $packname . "::" . $varname };
    @vals = @{ $packname . "::" . $aryname };
    &{ $packname . "::" . $funcname }("args");
    ($packname . "::" . $funcname) -> ("args");
}
#-----------------------------
eval "package $packname; \$'$val = \$$varname"; # set $main'val
die if $@;
#-----------------------------
printf "log2  of 100 is %.2f\n", log2(100);
printf "log10 of 100 is %.2f\n", log10(100);
#-----------------------------
$packname = 'main';
for ($i = 2; $i < 1000; $i++) {
    $logN = log($i);
    eval "sub ${packname}::log$i { log(shift) / $logN }";
    die if $@;
}
#-----------------------------
$packname = 'main';
for ($i = 2; $i < 1000; $i++) {
    my $logN = log($i);
    no strict 'refs';
    *{"${packname}::log$i"} = sub { log(shift) / $logN };
}
#-----------------------------
*blue       = \&Colors::blue;
*main::blue = \&Colors::azure;
#-----------------------------

