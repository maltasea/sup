
#-----------------------------
sub hypotenuse {
    return sqrt( ($_[0] ** 2) + ($_[1] ** 2) );
}

$diag = hypotenuse(3,4);  # $diag is 5
#-----------------------------
sub hypotenuse {
    my ($side1, $side2) = @_;
    return sqrt( ($side1 ** 2) + ($side2 ** 2) );
}
#-----------------------------
print hypotenuse(3, 4), "\n";               # prints 5

@a = (3, 4);
print hypotenuse(@a), "\n";                 # prints 5
#-----------------------------
@both = (@men, @women);
#-----------------------------
@nums = (1.4, 3.5, 6.7);
@ints = int_all(@nums);        # @nums unchanged
sub int_all {
    my @retlist = @_;          # make safe copy for return
    for my $n (@retlist) { $n = int($n) } 
    return @retlist;
} 
#-----------------------------
@nums = (1.4, 3.5, 6.7);
trunc_em(@nums);               # @nums now (1,3,6)
sub trunc_em {
    for (@_) { $_ = int($_) }  # truncate each argument
} 
#-----------------------------
$line = chomp(<>);                  # WRONG
#-----------------------------

