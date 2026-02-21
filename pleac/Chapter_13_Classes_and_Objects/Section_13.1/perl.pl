
#-----------------------------
sub new {
    my $class = shift;
    my $self  = { };
    bless($self, $class);
    return $self;
} 
#-----------------------------
sub new { bless( { }, shift ) }
#-----------------------------
sub new { bless({}) }
#-----------------------------
sub new {
    my $self = { };  # allocate anonymous hash
    bless($self);
    # init two sample attributes/data members/fields
    $self->{START} = time();  
    $self->{AGE}   = 0;
    return $self;
} 
#-----------------------------
sub new {
    my $classname  = shift;         # What class are we constructing?
    my $self      = {};             # Allocate new memory
    bless($self, $classname);       # Mark it of the right type
    $self->{START}  = 
time();
       # init data fields
    $self->{AGE}    = 
0;

    return $self;                   # And give it back
} 
#-----------------------------
sub new {
    my $classname  = shift;         # What class are we constructing?
    my $self      = {};             # Allocate new memory
    bless($self, $classname);       # Mark it of the right type
    $self->_init(@_);               # Call _init with remaining args
    return $self;
} 

# "private" method to initialize fields.  It always sets START to
# the current time, and AGE to 0.  If called with arguments, _init
# interprets them as key+value pairs to initialize the object with.
sub _init {
    my $self = shift;
    $self->{START} = 
time();

    $self->{AGE}   = 0;
    if (@_) {
        my %extra = @_;
        @$self{keys %extra} = values %extra;
    } 
} 
#-----------------------------

