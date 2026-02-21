
#-----------------------------
@array = split(//, $string);

@array = unpack("C*", $string);
#-----------------------------
    while (/(.)/g) { # . is never a newline here
        # do something with $1
    }
#-----------------------------
%seen = ();
$string = "an apple a day";
foreach $byte (split //, $string) {
    $seen{$byte}++;
}
print "unique chars are: ", sort(keys %seen), "\n";
unique chars are:  adelnpy
#-----------------------------
%seen = ();
$string = "an apple a day";
while ($string =~ /(.)/g) {
    $seen{$1}++;
}
print "unique chars are: ", sort(keys %seen), "\n";
unique chars are:  adelnpy
#-----------------------------
$sum = 0;
foreach $ascval (unpack("C*", $string)) {
    $sum += $ascval;
}
print "sum is $sum\n";
# prints "1248" if $string was "an apple a day"
#-----------------------------
$sum = unpack("%32C*", $string);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/sum
#-----------------------------
#% perl sum /etc/termcap
#1510
#-----------------------------
#% sum --sysv /etc/termcap
#1510 851 /etc/termcap
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/slowcat
#-----------------------------

