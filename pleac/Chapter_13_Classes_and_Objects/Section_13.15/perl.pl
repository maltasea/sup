
#-----------------------------
tie $s, "SomeClass"
#-----------------------------
SomeClass->
TIESCALAR()
#-----------------------------
$p = $s
#-----------------------------
$p = $obj->
FETCH()
#-----------------------------
$s = 10
#-----------------------------
$obj->STORE(10)
#-----------------------------
#!/usr/bin/perl
# demo_valuering - show tie class
use ValueRing;
tie $color, 'ValueRing', qw(red blue);
print "$color $color $color $color $color $color\n";
red blue red blue red blue


$color = 'green';
print "$color $color $color $color $color $color\n";
green red blue green red blue
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/ValueRing
#-----------------------------
no UnderScore;
#-----------------------------
#!/usr/bin/perl
# nounder_demo - show how to ban $_ from your program
no UnderScore;
@tests = (
    "Assignment"  => sub { $_ = "Bad" },
    "Reading"     => sub { print }, 
    "Matching"    => sub { $x = /badness/ },
    "Chop"        => sub { chop },
    "Filetest"    => sub { -x }, 
    "Nesting"     => sub { for (1..3) { print } },
);

while ( ($name, $code) = splice(@tests, 0, 2) ) {
    print "Testing $name: ";
    eval { &$code };
    print $@ ? "detected" : "missed!";
    print "\n";
} 
#-----------------------------
Testing Assignment: detected

Testing Reading: detected

Testing Matching: detected

Testing Chop: detected

Testing Filetest: detected

Testing Nesting: 123missed!
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/UnderScore
#-----------------------------
#!/usr/bin/perl 
# appendhash_demo - show magic hash that autoappends
use Tie::AppendHash;
tie %tab, 'Tie::AppendHash';

$tab{beer} = "guinness";
$tab{food} = "potatoes";
$tab{food} = "peas";

while (my($k, $v) = each %tab) {
    print "$k => [@$v]\n";
}
#-----------------------------
food => [potatoes peas]

beer => [guinness]
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/Tie/AppendHash.pm
#-----------------------------
#!/usr/bin/perl 
# folded_demo - demo hash that magically folds case
use Tie::Folded;
tie %tab, 'Tie::Folded';

$tab{VILLAIN}  = "big "; 
$tab{herOine}  = "red riding hood";
$tab{villain} .= "bad wolf";   

while ( my($k, $v) = each %tab ) {
    print "$k is $v\n";
}
#-----------------------------
heroine is red riding hood

villain is big bad wolf
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/Tie/Folded.pm
#-----------------------------
#!/usr/bin/perl -w
# revhash_demo - show hash that permits key *or* value lookups
use strict;
use Tie::RevHash;
my %tab;
tie %tab, 'Tie::RevHash';
%tab = qw{
    Red         Rojo
    Blue        Azul
    Green       Verde
};
$tab{EVIL} = [ "No way!", "Way!!" ];

while ( my($k, $v) = each %tab ) {
    print ref($k) ? "[@$k]" : $k, " => ",
        ref($v) ? "[@$v]" : $v, "\n";
} 
#-----------------------------
[No way! Way!!] => EVIL

EVIL => [No way! Way!!]

Blue => Azul

Green => Verde

Rojo => Red

Red => Rojo

Azul => Blue

Verde => Green
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/Tie/RevHash.pm
#-----------------------------
use Counter;
tie *CH, 'Counter';
while (<CH>) {
    print "Got $_\n";
} 
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/Counter
#-----------------------------
use Tie::Tee;
tie *TEE, 'Tie::Tee', *STDOUT, *STDERR;
print TEE "This line goes both places.\n";
#-----------------------------
#!/usr/bin/perl
# demo_tietee
use Tie::Tee;
use Symbol;

@handles = (*STDOUT);
for $i ( 1 .. 10 ) {
    push(@handles, $handle = gensym());
    open($handle, ">/tmp/teetest.$i");
} 

tie *TEE, 'Tie::Tee', @handles;
print TEE "This lines goes many places.\n";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch13/Tie/Tee.pm
#-----------------------------

