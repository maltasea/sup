
#-----------------------------
# does %HASH have a value for $KEY ?
if (exists($HASH{$KEY})) {
    # it exists
} else {
    # it doesn't
}
#-----------------------------
# %food_color per the introduction
foreach $name ("Banana", "Martini") {
    if (exists $food_color{$name}) {
        print "$name is a food.\n";
    } else {
        print "$name is a drink.\n";
    }
}

# Banana is a food.
# 
# Martini is a drink.
#-----------------------------
%age = ();
$age{"Toddler"}  = 3;
$age{"Unborn"}   = 0;
$age{"Phantasm"} = undef;

foreach $thing ("Toddler", "Unborn", "Phantasm", "Relic") {
    print "$thing: ";
    print "Exists " if exists $age{$thing};
    print "Defined " if defined $age{$thing};
    print "True " if $age{$thing};
    print "\n";
}

# Toddler: Exists Defined True 
# 
# Unborn: Exists Defined 
# 
# Phantasm: Exists 
# 
# Relic: 
#-----------------------------
%size = ();
while (<>) {
    chomp;
    next if $size{$_};              # WRONG attempt to skip
    $size{$_} = -s $_;
}
#-----------------------------
    next if exists $size{$_};
#-----------------------------

