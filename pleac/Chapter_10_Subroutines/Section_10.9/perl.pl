
#-----------------------------
($array_ref, $hash_ref) = somefunc();

sub somefunc {
    my @array;
    my %hash;

    # ...

    return ( \@array, \%hash );
}
#-----------------------------
sub fn { 
    .....
    return (\%a, \%b, \%c); # or                           
    return \(%a,  %b,  %c); # same thing
}
#-----------------------------
(%h0, %h1, %h2)  = fn();    # WRONG!
@array_of_hashes = fn();    # eg: $array_of_hashes[2]->{"keystring"}
($r0, $r1, $r2)  = fn();    # eg: $r2->{"keystring"}

#-----------------------------

