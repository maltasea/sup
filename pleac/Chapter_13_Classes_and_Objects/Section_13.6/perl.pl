
#-----------------------------
my $proto  = shift;
my $class  = ref($proto) || $proto;
my $parent = ref($proto) && $proto;
#-----------------------------
$ob1 = SomeClass->
new()
;
# later on
$ob2 = (ref $ob1)->
new();
#-----------------------------
$ob1 = Widget->new();
$ob2 = $ob1->new();
#-----------------------------
sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;

    my $self;
    # check whether we're shadowing a new from @ISA
    if (@ISA && $proto->SUPER::can('new') ) {
        $self = $proto->SUPER::new(@_);
    } else { 
        $self = {};
        bless ($self, $proto);
    }
    bless($self, $class);

    $self->{PARENT}  = $parent;
    $self->{START}   = time();   # init data fields
    $self->{AGE}     = 0;
    return $self;
} 
#-----------------------------

