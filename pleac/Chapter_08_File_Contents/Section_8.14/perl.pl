
#-----------------------------
$old_rs = $/;                       # save old $/
$/ = "\0";                          # NULL
seek(FH, $addr, SEEK_SET)           or die "Seek error: $!\n";
$string = <FH>;                     # read string
chomp $string;                      # remove NULL
$/ = $old_rs;                       # restore old $/
#-----------------------------
{
    local $/ = "\0";
    # ...
}                           # $/ is automatically restored
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/bgets
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/strings
#-----------------------------

