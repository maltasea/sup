
#-----------------------------
sub get_name {
    my $self = shift;
    return $self->{NAME};
} 

sub set_name {
    my $self      = shift;
    $self->{NAME} = shift;
} 
#-----------------------------
sub name {
    my $self = shift;
    if (@_) { $self->{NAME} = shift } 
    return $self->{NAME};
} 
#-----------------------------
sub age {
    my $self = shift;
    my $prev = $self->{AGE};
    if (@_) { $self->{AGE} = shift } 
    return $prev;
} 
# sample call of get and set: happy birthday!
$obj->age( 1 + $obj->age );
#-----------------------------
$him = Person->
new()
;
$him->{NAME} = "Sylvester";
$him->{AGE}  = 23;
#-----------------------------
use Carp;
sub name {
    my $self = shift;
    return $self->{NAME} unless @_;
    local $_ = shift;
    croak "too many arguments" if @_;
    if ($^W) {
        /[^\s\w'-]/         && carp "funny characters in name"; #'
        /\d/                && carp "numbers in name";
        /\S+(\s+\S+)+/      || carp "prefer multiword name";
        /\S/                || carp "name is blank";
    } 
    s/(\w+)/\u\L$1/g;       # enforce capitalization
    $self->{NAME} = $_;
} 
#-----------------------------
package Person;

# this is the same as before...
sub new {
     my $that  = shift;
     my $class = ref($that) || $that;
     my $self = {
           NAME  => undef,
           AGE   => undef,
           PEERS => [],
    };
    bless($self, $class);
    return $self;
}

use Alias qw(attr);
use vars qw($NAME $AGE @PEERS);

sub name {
    my $self = attr shift;
    if (@_) { $NAME = shift; }
    return    $NAME;
};

sub age {
    my $self = attr shift;
    if (@_) { $AGE = shift; }
    return    $AGE;
}

sub peers {
    my $self = attr shift;
    if (@_) { @PEERS = @_; }
    return    @PEERS;
}

sub exclaim {
    my $self = attr shift;
    return sprintf "Hi, I'm %s, age %d, working with %s",
            $NAME, $AGE, join(", ", @PEERS);
}

sub happy_birthday {
    my $self = attr shift;
    return ++$AGE;
}
#-----------------------------

