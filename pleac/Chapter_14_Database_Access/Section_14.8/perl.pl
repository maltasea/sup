
#-----------------------------
use MLDBM 'DB_File';
tie(%HASH, 'MLDBM', [... other DBM arguments]) or die $!;
#-----------------------------
# %hash is a tied hash
$hash{"Tom Christiansen"} = [ "book author", 'tchrist@perl.com' ];          
$hash{"Tom Boutell"} = [ "shareware author", 'boutell@boutell.com' ];

# names to compare
$name1 = "Tom Christiansen";
$name2 = "Tom Boutell";

$tom1 = $hash{$name1};      # snag local pointer
$tom2 = $hash{$name2};      # and another           

print "Two Toming: $tom1 $tom2\n";

Tom Toming: ARRAY(0x73048) ARRAY(0x73e4c)
#-----------------------------
if ($tom1->[0] eq $tom2->[0] &&
    $tom1->[1] eq $tom2->[1]) {
    print "You're having runtime fun with one Tom made two.\n";
} else {
    print "No two Toms are ever alike.\n";
}
#-----------------------------
if ($hash{$name1}->[0] eq $hash{$name2}->[0] &&     # INEFFICIENT
    $hash{$name1}->[1] eq $hash{$name2}->[1]) {
    print "You're having runtime fun with one Tom made two.\n";
} else {
    print "No two Toms are ever alike.\n";
}
#-----------------------------
$hash{"Tom Boutell"}->[0] = "Poet Programmer";      # WRONG
#-----------------------------
$entry = $hash{"Tom Boutell"};                      # RIGHT
$entry->[0] = "Poet Programmer";
$hash{"Tom Boutell"} = $entry;
#-----------------------------

