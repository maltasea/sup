
#-----------------------------
sub DESTROY {
    my $self = shift;
    printf("$self dying at %s\n", scalar localtime);
} 
#-----------------------------
$self->{WHATEVER} = $self;
#-----------------------------

