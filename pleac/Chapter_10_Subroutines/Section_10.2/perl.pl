
#-----------------------------
sub somefunc {
    my $variable;                 # $variable is invisible outside somefunc()
    my ($another, @an_array, %a_hash);     # declaring many variables at once

    # ...
}
#-----------------------------
my ($name, $age) = @ARGV;
my $start        = fetch_time();
#-----------------------------
my ($a, $b) = @pair;
my $c = fetch_time();

sub check_x {
    my $x = $_[0];       
    my $y = "whatever";  
    run_check();
    if ($condition) {
        print "got $x\n";
    }
}
#-----------------------------
sub save_array {
    my @arguments = @_;
    push(@Global_Array, \@arguments);
}
#-----------------------------

