
#-----------------------------
sub AUTOLOAD {
    use vars qw($AUTOLOAD);
    my $color = $AUTOLOAD;
    $color =~ s/.*:://;
    return "<FONT COLOR='$color'>@_</FONT>";
} 
#note: sub chartreuse isn't defined.
print chartreuse("stuff");
#-----------------------------
{
    local *yellow = \&violet;  
    local (*red, *green) = (\&green, \&red);
    print_stuff();
} 
#-----------------------------

