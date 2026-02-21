
#-----------------------------
push(@{ $hash{"KEYNAME"} }, "new value");
#-----------------------------
foreach $string (keys %hash) {
    print "$string: @{$hash{$string}}\n"; 
} 
#-----------------------------
$hash{"a key"} = [ 3, 4, 5 ];       # anonymous array
#-----------------------------
@values = @{ $hash{"a key"} };
#-----------------------------
push @{ $hash{"a key"} }, $value;
#-----------------------------
@residents = @{ $phone2name{$number} };
#-----------------------------
@residents = exists( $phone2name{$number} )
                ? @{ $phone2name{$number} }
                : ();
#-----------------------------

