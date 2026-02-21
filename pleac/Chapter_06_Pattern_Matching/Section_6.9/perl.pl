
#-----------------------------
sub glob2pat {
    my $globstr = shift;
    my %patmap = (
	 '*' => '.*',
	 '?' => '.',
	 '[' => '[',
	 ']' => ']',
    );
    $globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;
    return '^' . $globstr . '$'; #'
}
#-----------------------------

