
#-----------------------------
use LWP::Simple;
$content = get($URL);
#-----------------------------
use LWP::Simple;
unless (defined ($content = get $URL)) {
    die "could not get $URL\n";
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/titlebytes
#-----------------------------
#% titlebytes http://www.tpj.com/
#http://www.tpj.com/ =>
#    The Perl Journal (109 lines, 4530 bytes)
#-----------------------------

