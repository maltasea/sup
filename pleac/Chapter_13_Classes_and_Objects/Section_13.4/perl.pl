
#-----------------------------
package Person;

$Body_Count = 0; 

sub population { return $Body_Count }

sub new {                                   # constructor
    $Body_Count++;
    return bless({}, shift);
}

sub DESTROY { --$BodyCount }                # destructor

# later, the user can say this:
package main;

for (1..10) { push @people, Person->new }
printf "There are %d people alive.\n", Person->population();

There are 10 people alive.
#-----------------------------
$him = Person->
new()
;
$him->gender("male");

$her = Person->
new()
;
$her->gender("female");
#-----------------------------
FixedArray->Max_Bounds(100);                # set for whole class
$alpha = FixedArray->new();
printf "Bound on alpha is %d\n", $alpha->Max_Bounds();
100

$beta = FixedArray->new();
$beta->Max_Bounds(50);                      # still sets for whole class
printf "Bound on alpha is %d\n", $alpha->Max_Bounds();
50
#-----------------------------
package FixedArray;
$Bounds = 7;  # default
sub new { bless( {}, shift ) }
sub Max_Bounds {
    my $proto  = shift;
    $Bounds    = shift if @_;          # allow updates
    return $Bounds;
} 
#-----------------------------
sub Max_Bounds { $Bounds }
#-----------------------------
sub new {
    my $class = shift;
    my $self = bless({}, $class);
    $self->{Max_Bounds_ref} = \$Bounds;
    return $self;
} 
#-----------------------------

