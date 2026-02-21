
#-----------------------------
package Person;
sub new {
    my $class = shift;
    my $self  = { };
    return bless $self, $class;
} 
sub name {
    my $self = shift;
    $self->{NAME} = shift if @_;
    return $self->{NAME};
} 
sub age {
    my $self = shift;
    $self->{AGE} = shift if @_;
    return $self->{AGE};
} 
#-----------------------------
use Person;
my $dude = Person->
new()
;
$dude->name("Jason");
$dude->age(23);
printf "%s is age %d.\n", $dude->name, $dude->age;
#-----------------------------
package Employee;
use Person;
@ISA = ("Person");
1;
#-----------------------------
use Employee;
my $empl = Employee->
new()
;
$empl->name("Jason");
$empl->age(23);
printf "%s is age %d.\n", $empl->name, $empl->age;
#-----------------------------
$him = Person::
new()
;               # WRONG
#-----------------------------

