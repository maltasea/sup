
#-----------------------------
{
    my $variable;
    sub mysub {
        # ... accessing $variable
    }
}
#-----------------------------
BEGIN {
    my $variable = 1;                       # initial value
    sub othersub {                          # ... accessing $variable
    }
}
#-----------------------------
{
    my $counter;
    sub next_counter { return ++$counter }
}
#-----------------------------
BEGIN {
    my $counter = 42;
    sub next_counter { return ++$counter }
    sub prev_counter { return --$counter }
}
#-----------------------------

