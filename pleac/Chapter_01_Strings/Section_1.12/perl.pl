
#-----------------------------
use Text::Wrap;
@OUTPUT = wrap($LEADTAB, $NEXTTAB, @PARA);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/wrapdemo
#-----------------------------
01234567890123456789

    Folding and

  splicing is the

  work of an

  editor, not a

  mere collection

  of silicon and

  mobile electrons!
#-----------------------------
# merge multiple lines into one, then wrap one long line
use Text::Wrap;
undef $/;
print wrap('', '', split(/\s*\n\s*/, <>));
#-----------------------------
use Text::Wrap      qw(&wrap $columns);
use Term::ReadKey   qw(GetTerminalSize);
($columns) = GetTerminalSize();
($/, $\)  = ('', "\n\n");   # read by paragraph, output 2 newlines
while (<>) {                # grab a full paragraph
    s/\s*\n\s*/ /g;         # convert intervening newlines to spaces
    print wrap('', '', $_); # and format
}
#-----------------------------

