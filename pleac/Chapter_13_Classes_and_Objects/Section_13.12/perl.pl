
#-----------------------------
sub Employee::age {
    my $self = shift;
    $self->{Employee_age} = shift if @_;
    return $self->{Employee_age};
} 
#-----------------------------
package Person;
use Class::Attributes;  # see explanation below
mkattr qw(name age peers parent);
#-----------------------------
package Employee;
@ISA = qw(Person);
use Class::Attributes;
mkattr qw(salary age boss);
#-----------------------------
package Class::Attributes;
use strict;
use Carp;
use Exporter ();
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(mkattr);
sub mkattr {
    my $hispack = caller();
    for my $attr (@_) {
        my($field, $method);
        $method = "${hispack}::$attr";
        ($field = $method) =~ s/:/_/g; 
        no strict 'refs'; # here comes the kluglich bit
        *$method = sub {
            my $self = shift;
            confess "too many arguments" if @_ > 1;
            $self->{$field} = shift if @_;
            return $self->{$field};   
        };
    } 
} 
1;
#-----------------------------

