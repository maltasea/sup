
#-----------------------------
use overload ('<=>' => \&threeway_compare);
sub threeway_compare {
    my ($s1, $s2) = @_;
    return uc($s1->{NAME}) cmp uc($s2->{NAME});
} 

use overload ( '""'  => \&stringify );
sub stringify {
    my $self = shift;
    return sprintf "%s (%05d)", 
            ucfirst(lc($self->{NAME})),
            $self->{IDNUM};
}
#-----------------------------
package TimeNumber;
use overload '+' => \&my_plus,
             '-' => \&my_minus,
             '*' => \&my_star,
             '/' => \&my_slash;
#-----------------------------
sub my_plus {
    my($left, $right) = @_;
    my $answer = $left->
new();

    $answer->{SECONDS} = $left->{SECONDS} + $right->{SECONDS};
    $answer->{MINUTES} = $left->{MINUTES} + $right->{MINUTES};
    $answer->{HOURS}   = $left->{HOURS}   + $right->{HOURS};

    if ($answer->{SECONDS} >= 60) {
        $answer->{SECONDS} %= 60;
        $answer->{MINUTES} ++;
    } 

    if ($answer->{MINUTES} >= 60) {
        $answer->{MINUTES} %= 60;
        $answer->{HOURS}   ++;
    } 

    return $answer;

} 
#-----------------------------
#!/usr/bin/perl
# show_strnum - demo operator overloading
use StrNum;           
    
$x = StrNum("Red"); $y = StrNum("Black");
$z = $x + $y; $r = $z * 3;
print "values are $x, $y, $z, and $r\n";
print "$x is ", $x < $y ? "LT" : "GE", " $y\n";

# values are Red, Black, RedBlack, and RedBlackRedBlackRedBlack
# Red is GE Black
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/StrNum
#-----------------------------
#!/usr/bin/perl
# demo_fixnum - show operator overloading
use FixNum;

FixNum->places(5);

$x = FixNum->new(40);
$y = FixNum->new(12);

print "sum of $x and $y is ", $x + $y, "\n";
print "product of $x and $y is ", $x * $y, "\n";

$z = $x / $y;
printf "$z has %d places\n", $z->places;
$z->places(2) unless $z->places;
print "div of $x by $y is $z\n";
print "square of that is ", $z * $z, "\n";

sum of STRFixNum: 40 and STRFixNum: 12 is STRFixNum: 52

product of STRFixNum: 40 and STRFixNum: 12 is STRFixNum: 480

STRFixNum: 3 has 0 places

div of STRFixNum: 40 by STRFixNum: 12 is STRFixNum: 3.33

square of that is STRFixNum: 11.11
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/FixNum
#-----------------------------

