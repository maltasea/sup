
#-----------------------------
use Class::Struct;          # load struct-building module

struct Person => {          # create a definition for a "Person"
    name   => '$',          #    name field is a scalar
    age    => '$',          #    age field is also a scalar
    peers  => '@',          #    but peers field is an array (reference)
};

my $p = Person->
new()
;      # allocate an empty Person struct

$p->name("Jason Smythe");                   # set its name field
$p->age(13);                                # set its age field
$p->peers( ["Wilbur", "Ralph", "Fred" ] );  # set its peers field

# or this way:
@{$p->peers} = ("Wilbur", "Ralph", "Fred");

# fetch various values, including the zeroth friend
printf "At age %d, %s's first friend is %s.\n",
    $p->age, $p->name, $p->peers(0);
#-----------------------------
use Class::Struct;

struct Person => {name => '$',      age  => '$'};  #'
struct Family => {head => 'Person', address => '$', members => '@'};  #'

$folks  = Family->
new();

$dad    = $folks->head;
$dad->name("John");
$dad->age(34);

printf("%s's age is %d\n", $folks->head->name, $folks->head->age);
#-----------------------------
sub Person::age {
    use Carp;
    my ($self, $age) = @_;
    if    (@_  > 2) {  confess "too many arguments" } 
    elsif (@_ == 1) {  return $struct->{'age'}      }
    elsif (@_ == 2) {
        carp "age `$age' isn't numeric"   if $age !~ /^\d+/;
        carp "age `$age' is unreasonable" if $age > 150;
        $self->{'age'} = $age;
    } 
} 
#-----------------------------
if ($^W) { 
    carp "age `$age' isn't numeric"   if $age !~ /^\d+/;
    carp "age `$age' is unreasonable" if $age > 150;
}
#-----------------------------
my $gripe = $^W ? \&carp : \&croak;
$gripe->("age `$age' isn't numeric")   if $age !~ /^\d+/;
$gripe->("age `$age' is unreasonable") if $age > 150;
#-----------------------------
struct Family => [head => 'Person', address => '$', members => '@'];  #'
#-----------------------------
struct Card => { 
    name    => '$',
    color   => '$',
    cost    => '$',
    type    => '$',
    release => '$',
    text    => '$',
};
#-----------------------------
struct Card => map { $_ => '$' } qw(name color cost type release text); #'
#-----------------------------
struct hostent => { reverse qw{
    $ name
    @ aliases
    $ addrtype
    $ length
    @ addr_list
}};
#-----------------------------
#define h_type h_addrtype
#define h_addr h_addr_list[0]
#-----------------------------
# make (hostent object)->
type()
 same as (hostent object)->
addrtype()

*hostent::type = \&hostent::addrtype;

# make (hostenv object)->
addr()
 same as (hostenv object)->addr_list(0)
sub hostent::addr { shift->addr_list(0,@_) }
#-----------------------------
package Extra::hostent;
use Net::hostent;
@ISA = qw(hostent);
sub addr { shift->addr_list(0,@_) } 
1;
#-----------------------------

