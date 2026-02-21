
#-----------------------------
$number = hex($hexadecimal);         # hexadecimal
$number = oct($octal);               # octal
#-----------------------------
print "Gimme a number in decimal, octal, or hex: ";
$num = <STDIN>;
chomp $num;
exit unless defined $num;
$num = oct($num) if $num =~ /^0/; # does both oct and hex
printf "%d %x %o\n", $num, $num, $num;
#-----------------------------
print "Enter file permission in octal: ";
$permissions = <STDIN>;
die "Exiting ...\n" unless defined $permissions;
chomp $permissions;
$permissions = oct($permissions);   # permissions always octal
print "The decimal value is $permissions\n";
#-----------------------------

