
#-----------------------------
# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

fisher_yates_shuffle( \@array );    # permutes @array in place
#-----------------------------
$permutations = factorial( scalar @array );
@shuffle = @array [ n2perm( 1+int(rand $permutations), $#array ) ];
#-----------------------------
sub naive_shuffle {                             # don't do this
    for (my $i = 0; $i < @_; $i++) {
        my $j = int rand @_;                    # pick random element
        ($_[$i], $_[$j]) = ($_[$j], $_[$i]);    # swap 'em
    }
}
#-----------------------------

