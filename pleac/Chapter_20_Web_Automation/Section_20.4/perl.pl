
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/text2html
#-----------------------------
BEGIN {
    print "<TABLE>";
    $_ = encode_entities(scalar <>);
    s/\n\s+/ /g;  # continuation lines
    while ( /^(\S+?:)\s*(.*)$/gm ) {                # parse heading
        print "<TR><TH ALIGN='LEFT'>$1</TH><TD>$2</TD></TR>\n";
    }
    print "</TABLE><HR>";
}
#-----------------------------

