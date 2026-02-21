
#-----------------------------
while (/(\d+)/g) {
    print "Found $1\n";
}
#-----------------------------
$n = "   49 here";
$n =~ s/\G /0/g;
print $n;
00049 here
#-----------------------------
while (/\G,?(\d+)/g) {
    print "Found number $1\n";
}
#-----------------------------
$_ = "The year 1752 lost 10 days on the 3rd of September";

while (/(\d+)/gc) {
    print "Found number $1\n";
}

if (/\G(\S+)/g) {
    print "Found $1 after the last number.\n";
}

#Found number 1752
#
#Found number 10
#
#Found number 3
#
#Found rd after the last number.
#-----------------------------
print "The position in \$a is ", pos($a);
pos($a) = 30;
print "The position in \$_ is ", pos;
pos = 30;
#-----------------------------

