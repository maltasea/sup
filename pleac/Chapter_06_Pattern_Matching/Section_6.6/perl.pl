
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/killtags
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/headerfy
#-----------------------------
#% perl -00pe 's{\A(Chapter\s+\d+\s*:.*)}{<H1>$1</H1>}gx' datafile
#-----------------------------
$/ = '';            # paragraph read mode for readline access
while (<ARGV>) {
    while (m#^START(.*?)^END#sm) {  # /s makes . span line boundaries
                                    # /m makes ^ match near newlines
        print "chunk $. in $ARGV has <<$1>>\n";
    }
}
#-----------------------------

