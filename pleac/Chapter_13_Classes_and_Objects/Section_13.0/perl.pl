
#-----------------------------
$object = {};                       # hash reference
bless($object, "Data::Encoder");    # bless $object into Data::Encoder class
bless($object);                     # bless $object into current package
#-----------------------------
$obj = [3,5];
print ref($obj), " ", $obj->[1], "\n";
bless($obj, "Human::Cannibal");
print ref($obj), " ", $obj->[1], "\n";

ARRAY 5

Human::Cannibal 5
#-----------------------------
$obj->{Stomach} = "Empty";   # directly accessing an object's contents
$obj->{NAME}    = "Thag";        # uppercase field name to make it stand out (optional)
#-----------------------------
$encoded = $object->encode("data");
#-----------------------------
$encoded = Data::Encoder->encode("data");
#-----------------------------
sub new {
    my $class = shift;
    my $self  = {};         # allocate new hash for object
    bless($self, $class);
    return $self;
}
#-----------------------------
$object = Class->new();
#-----------------------------
$object = Class::new("Class");
#-----------------------------
sub class_only_method {
    my $class = shift;
    die "class method called on object" if ref $class;
    # more code here
} 
#-----------------------------
sub instance_only_method {
    my $self = shift;
    die "instance method called on class" unless ref $self;
    # more code here
} 
#-----------------------------
$lector = new Human::Cannibal;
feed $lector "Zak";
move $lector "New York";
#-----------------------------
$lector = Human::Cannibal->
new();

$lector->feed("Zak");
$lector->move("New York");
#-----------------------------
printf STDERR "stuff here\n";
#-----------------------------
move $obj->{FIELD};                 # probably wrong
move $ary[$i];                      # probably wrong
#-----------------------------
$obj->move->{FIELD};                # Surprise!
$ary->move->[$i];                   # Surprise!
#-----------------------------
$obj->{FIELD}->
move()
;              # Nope, you wish
$ary[$i]->
move;
                     # Nope, you wish
#-----------------------------

