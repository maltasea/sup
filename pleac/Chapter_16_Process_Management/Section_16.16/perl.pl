
#-----------------------------
# the signal handler
sub ding {
    $SIG{INT} = \&ding;
    warn "\aEnter your name!\n";
}

# prompt for name, overriding SIGINT
sub get_name {
    local $SIG{INT} = \&ding;
    my $name;

    print "Kindly Stranger, please enter your name: ";
    chomp( $name = <> );
    return $name;
}
#-----------------------------

