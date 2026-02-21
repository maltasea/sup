
#-----------------------------
@MATCHING = grep { TEST ($_) } @LIST;
#-----------------------------
@matching = ();
foreach (@list) {
    push(@matching, $_) if TEST ($_);
}
#-----------------------------
@bigs = grep { $_ > 1_000_000 } @nums;
@pigs = grep { $users{$_} > 1e7 } keys %users;
#-----------------------------
@matching = grep { /^gnat / } `who`;
#-----------------------------
@engineers = grep { $_->position() eq 'Engineer' } @employees;
#-----------------------------
@secondary_assistance = grep { $_->income >= 26_000 &&
                               $_->income <  30_000 }
                        @applicants;
#-----------------------------

