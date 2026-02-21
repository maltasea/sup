
#-----------------------------
use Term::ReadLine;

$term = Term::ReadLine->new("APP DESCRIPTION");
$OUT = $term->OUT || *STDOUT;

$term->addhistory($fake_line);
$line = $term->readline(PROMPT);

print $OUT "Any program output\n";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch15/vbsh
#-----------------------------
$term->addhistory($seed_line);
#-----------------------------
$term->remove_history($line_number);
#-----------------------------
@history = $term->GetHistory;
#-----------------------------

