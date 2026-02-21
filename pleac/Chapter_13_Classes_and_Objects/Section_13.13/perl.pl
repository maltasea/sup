
#-----------------------------
$node->{NEXT} = $node;
#-----------------------------
package Ring;

# return an empty ring structure
sub new {
    my $class = shift;
    my $node  = { };
    $node->{NEXT} = $node->{PREV} = $node;
    my $self  = { DUMMY => $node, COUNT => 0 };
    bless $self, $class;
    return $self;
}
#-----------------------------
use Ring;

$COUNT = 1000;
for (1 .. 20) { 
    my $r = Ring->
new()
;
    for ($i = 0; $i < $COUNT; $i++) { $r->insert($i) } 
}
#-----------------------------
# when a Ring is destroyed, destroy the ring structure it contains 
sub DESTROY {
    my $ring = shift;
    my $node;
    for ( $node  =  $ring->{DUMMY}->{NEXT};
          $node !=  $ring->{DUMMY}; 
          $node  =  $node->{NEXT} )
    {
             $ring->delete_node($node);
    } 
    $node->{PREV} = $node->{NEXT} = undef;
} 

# delete a node from the ring structure
sub delete_node {
    my ($ring, $node) = @_;
    $node->{PREV}->{NEXT} = $node->{NEXT};
    $node->{NEXT}->{PREV} = $node->{PREV};
    --$ring->{COUNT};
} 
#-----------------------------
# $node = $ring->search( $value ) : find $value in the ring
# structure in $node
sub search {
    my ($ring, $value) = @_;
    my $node = $ring->{DUMMY}->{NEXT};
    while ($node != $ring->{DUMMY} && $node->{VALUE} != $value) {
          $node = $node->{NEXT};
    }
    return $node;
} 

# $ring->insert( $value ) : insert $value into the ring structure
sub insert {
    my ($ring, $value) = @_;
    my $node = { VALUE => $value };
    $node->{NEXT} = $ring->{DUMMY}->{NEXT};
    $ring->{DUMMY}->{NEXT}->{PREV} = $node;
    $ring->{DUMMY}->{NEXT} = $node;
    $node->{PREV} = $ring->{DUMMY};
    ++$ring->{COUNT};
} 

# $ring->delete_value( $value ) : delete a node from the ring
# structure by value
sub delete_value {
    my ($ring, $value) = @_;
    my $node = $ring->search($value);
    return if $node == $ring->{DUMMY};
    $ring->delete_node($node);
}


1;
#-----------------------------

