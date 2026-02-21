
#-----------------------------
sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}
#-----------------------------
# more reasonable web counter :-)
use Math::TrulyRandom;
$hits = truly_random_value();       # negative hits!
$output = "Your web page received $hits accesses last month.\n";
print commify($output);
Your web page received -1,740,525,205 accesses last month.
#-----------------------------

