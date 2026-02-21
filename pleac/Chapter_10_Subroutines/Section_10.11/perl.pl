
#-----------------------------
@results = myfunc 3, 5;
#-----------------------------
@results = myfunc(3, 5);
#-----------------------------
sub myfunc($);
@results = myfunc 3, 5;
#-----------------------------
@results = ( myfunc(3), 5 );
#-----------------------------
sub LOCK_SH () { 1 }
sub LOCK_EX () { 2 }
sub LOCK_UN () { 4 }
#-----------------------------
sub mypush (\@@) {
  my $array_ref = shift;
  my @remainder = @_;

  # ...
}
#-----------------------------
 mypush( $x > 10 ? @a : @b , 3, 5 );          # WRONG
#-----------------------------
 mypush( @{ $x > 10 ? \@a : \@b }, 3, 5 );    # RIGHT
#-----------------------------
sub hpush(\%@) {
    my $href = shift;
    while ( my ($k, $v) = splice(@_, 0, 2) ) {
        $href->{$k} = $v;
    } 
} 
hpush(%pieces, "queen" => 9, "rook" => 5);
#-----------------------------

