
#-----------------------------
if ($var =~ /^[A-Za-z]+$/) {
    # it is purely alphabetic
}
#-----------------------------
use locale;
if ($var =~ /^[^\W\d_]+$/) {
    print "var is purely alphabetic\n";
}
#-----------------------------
use locale;
use POSIX 'locale_h';

# the following locale string might be different on your system
unless (setlocale(LC_ALL, "fr_CA.ISO8859-1")) {
    die "couldn't set locale to French Canadian\n";
}

while (<DATA>) {
    chomp;
    if (/^[^\W\d_]+$/) {
        print "$_: alphabetic\n";
    } else {
        print "$_: line noise\n";
    }
}

#__END__
#silly
#façade
#coöperate
#niño
#Renée
#Molière
#hæmoglobin
#naïve
#tschüß
#random!stuff#here
#-----------------------------

