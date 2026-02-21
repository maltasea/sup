
#-----------------------------
sub meth { 
    my $self = shift;
    $self->SUPER::
meth()
;
}
#-----------------------------
$self->
meth();
                # Call wherever first meth is found
$self->Where::
meth();
         # Start looking in package "Where"
$self->SUPER::
meth(); 
        # Call overridden version
#-----------------------------
sub new {
    my $classname  = shift;         # What class are we constructing?
    my $self       = $classname->SUPER::new(@_);
    $self->_init(@_);
    return $self;                   # And give it back
} 

sub _init {
    my $self = shift;
    $self->{START}   = time();   # init data fields
    $self->{AGE}     = 0;
    $self->{EXTRA}   = { @_ };   # anything extra
}
#-----------------------------
$obj = Widget->new( haircolor => red, freckles => 121 );
#-----------------------------
my $self = bless {}, $class;
for my $class (@ISA) {
    my $meth = $class . "::_init";
    $self->$meth(@_) if $class->can("_init");
} 
#-----------------------------

