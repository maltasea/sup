
#-----------------------------
match( $string, $pattern );
subst( $string, $pattern, $replacement );
#-----------------------------
$meadow =~ m/sheep/;   # True if $meadow contains "sheep"
$meadow !~ m/sheep/;   # True if $meadow doesn't contain "sheep"
$meadow =~ s/old/new/; # Replace "old" with "new" in $meadow
#-----------------------------
# Fine bovines demand fine toreadors.
# Muskoxen are a polar ovibovine species.
# Grooviness went out of fashion decades ago.
#-----------------------------
# Ovines are found typically in oviaries.
#-----------------------------
if ($meadow =~ /\bovines?\b/i) { print "Here be sheep!" }
#-----------------------------
$string = "good food";
$string =~ s/o*/e/;
#-----------------------------
# good food
# 
# geod food
# 
# geed food
# 
# geed feed
# 
# ged food
# 
# ged fed
# 
# egood food
#-----------------------------
#% echo ababacaca | perl -ne 'print "$&\n" if /(a|ba|b)+(a|ac)+/'
#ababa
#-----------------------------
#% echo ababacaca | 
#    awk 'match($0,/(a|ba|b)+(a|ac)+/) { print substr($0, RSTART, RLENGTH) }'
#ababacaca
#-----------------------------
while (m/(\d+)/g) {
    print "Found number $1\n";
}
#-----------------------------
@numbers = m/(\d+)/g;
#-----------------------------
$digits = "123456789";
@nonlap = $digits =~ /(\d\d\d)/g;
@yeslap = $digits =~ /(?=(\d\d\d))/g;
print "Non-overlapping:  @nonlap\n";
print "Overlapping:      @yeslap\n";
# Non-overlapping:  123 456 789

# Overlapping:      123 234 345 456 567 678 789
#-----------------------------
$string = "And little lambs eat ivy";
$string =~ /l[^s]*s/;
print "($`) ($&) ($')\n";
# (And ) (little lambs) ( eat ivy)
#-----------------------------

