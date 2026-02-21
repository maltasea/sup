
#-----------------------------
($plain_text = $html_text) =~ s/<[^>]*>//gs;     #WRONG
#-----------------------------
use HTML::Parse;
use HTML::FormatText;
$plain_text = HTML::FormatText->new->format(parse_html($html_text));
#-----------------------------
#% perl -pe 's/<[^>]*>//g' file
#-----------------------------
#<IMG SRC = "foo.gif"
#     ALT = "Flurp!">
#-----------------------------
#% perl -0777 -pe 's/<[^>]*>//gs' file
#-----------------------------
{
    local $/;               # temporary whole-file input mode
    $html = <FILE>;
    $html =~ s/<[^>]*>//gs;
}
#-----------------------------
#<IMG SRC = "foo.gif" ALT = "A > B">
#
#<!-- <A comment> -->
#
#<script>if (a<b && a>c)</script>
#
#<# Just data #>
#
#<![INCLUDE CDATA [ >>>>>>>>>>>> ]]>
#-----------------------------
#<!-- This section commented out.
#    <B>You can't see me!</B>
#-->
#-----------------------------
package MyParser;
use HTML::Parser;
use HTML::Entities qw(decode_entities);

@ISA = qw(HTML::Parser);

sub text {
    my($self, $text) = @_;
    print decode_entities($text);
}

package main;
MyParser->new->parse_file(*F);
#-----------------------------
($title) = ($html =~ m#<TITLE>\s*(.*?)\s*</TITLE>#is);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/htitle
#-----------------------------
#% htitle http://www.ora.com
#www.oreilly.com -- Welcome to O'Reilly & Associates!
#
#% htitle http://www.perl.com/ http://www.perl.com/nullvoid
#http://www.perl.com/: The www.perl.com Home Page
#http://www.perl.com/nullvoid: 404 File Not Found
#-----------------------------

