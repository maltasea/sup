
#-----------------------------
#You owe $debt to me.
#-----------------------------
$text =~ s/\$(\w+)/${$1}/g;
#-----------------------------
$text =~ s/(\$\w+)/$1/gee;
#-----------------------------
use vars qw($rows $cols);
no strict 'refs';                   # for ${$1}/g below
my $text;

($rows, $cols) = (24, 80);
$text = q(I am $rows high and $cols long);  # like single quotes!
$text =~ s/\$(\w+)/${$1}/g;
print $text;
I am 24 high and 80 long
#-----------------------------
$text = "I am 17 years old";
$text =~ s/(\d+)/2 * $1/eg; 
#-----------------------------
2 * 17
#-----------------------------
$text = 'I am $AGE years old';      # note single quotes
$text =~ s/(\$\w+)/$1/eg;           # WRONG
#-----------------------------
'$AGE'
#-----------------------------
$text =~ s/(\$\w+)/$1/eeg;          # finds my() variables
#-----------------------------
# expand variables in $text, but put an error message in
# if the variable isn't defined
$text =~ s{
     \$                         # find a literal dollar sign
    (\w+)                       # find a "word" and store it in $1
}{
    no strict 'refs';           # for $$1 below
    if (defined ${$1}) {
        ${$1};                  # expand global variables only
    } else {
        "[NO VARIABLE: \$$1]";  # error msg
    }
}egx;
#-----------------------------

