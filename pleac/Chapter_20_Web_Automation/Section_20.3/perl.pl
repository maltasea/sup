
#-----------------------------
use HTML::LinkExtor;

$parser = HTML::LinkExtor->new(undef, $base_url);
$parser->parse_file($filename);
@links = $parser->links;
foreach $linkarray (@links) {
    my @element = @$linkarray;
    my $elt_type = shift @element;                  # element type

    # possibly test whether this is an element we're interested in
    while (@element) {
        # extract the next attribute and its value
        my ($attr_name, $attr_value) = splice(@element, 0, 2);
        # ... do something with them ...
    }
}
#-----------------------------
<A HREF="http://www.perl.com/">Home page</A>
<IMG SRC="images/big.gif" LOWSRC="images/big-lowres.gif">
#-----------------------------
[
  [ a,   href   => "http://www.perl.com/" ],
  [ img, src    => "images/big.gif",
         lowsrc => "images/big-lowres.gif" ]
]
#-----------------------------
if ($elt_type eq 'a' && $attr_name eq 'href') {
    print "ANCHOR: $attr_value\n" 
        if $attr_value->scheme =~ /http|ftp/;
}
if ($elt_type eq 'img' && $attr_name eq 'src') {
    print "IMAGE:  $attr_value\n";
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/xurl
#-----------------------------
#% xurl http://www.perl.com/CPAN
#ftp://ftp@ftp.perl.com/CPAN/CPAN.html
#
#http://language.perl.com/misc/CPAN.cgi
#
#http://language.perl.com/misc/cpan_module
#
#http://language.perl.com/misc/getcpan
#
#http://www.perl.com/index.html
#
#http://www.perl.com/gifs/lcb.xbm
#-----------------------------
<URL:http://www.perl.com>
#-----------------------------
@URLs = ($message =~ /<URL:(.*?)>/g);
#-----------------------------

