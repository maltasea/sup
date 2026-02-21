
#-----------------------------
use Term::ReadKey;

($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
#-----------------------------
use Term::ReadKey;

($width) = GetTerminalSize();
die "You must have at least 10 characters" unless $width >= 10;

$max = 0;
foreach (@values) {
    $max = $_ if $max < $_;
}

$ratio = ($width-10)/$max;          # chars per unit
foreach (@values) {
    printf("%8.1f %s\n", $_, "*" x ($ratio*$_));
}
#-----------------------------

