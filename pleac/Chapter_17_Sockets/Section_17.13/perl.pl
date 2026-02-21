
#-----------------------------
# ^^INCLUDE^^ include/perl/ch17/nonforker
#-----------------------------
while ($inbuffer{$client} =~ s/(.*\n)//) {
    push( @{$ready{$client}}, $1 );
}
#-----------------------------
$outbuffer{$client} .= $request;
#-----------------------------

