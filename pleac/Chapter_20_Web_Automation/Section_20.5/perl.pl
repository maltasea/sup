
#-----------------------------
$ascii = `lynx -dump $filename`;
#-----------------------------
use HTML::FormatText;
use HTML::Parse;

$html = parse_htmlfile($filename);
$formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);
$ascii = $formatter->format($html);
#-----------------------------
use HTML::TreeBuilder;
use HTML::FormatText;

$html = HTML::TreeBuilder->new();
$html->parse($document);

$formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);

$ascii = $formatter->format($html);
#-----------------------------

