
#-----------------------------
sub parse_csv {
    my $text = shift;      # record containing comma-separated values
    my @new  = ();
    push(@new, $+) while $text =~ m{
        # the first part groups the phrase inside the quotes.
        # see explanation of this pattern in MRE
        "([^\"\\]*(?:\\.[^\"\\]*)*)",?
           |  ([^,]+),?
           | ,
       }gx;
       push(@new, undef) if substr($text, -1,1) eq ',';
       return @new;      # list of values that were comma-separated
}
#-----------------------------
use
Text::ParseWords;

sub parse_csv {
    return quoteword(",",0, $_[0]);
}
#-----------------------------
$line = q<XYZZY,"","O'Reilly, Inc","Wall, Larry","a \"glug\" bit,",5,
    "Error, Core Dumped">;
@fields = parse_csv($line);
for ($i = 0; $i < @fields; $i++) {
    print "$i : $fields[$i]\n";
}
#0 : XYZZY
#
#1 :
#
#2 : O'Reilly, Inc
#
#3 : Wall, Larry
#
#4 : a \"glug\" bit,
#
#5 : 5
#
#6 : Error, Core Dumped
#-----------------------------

