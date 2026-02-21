
#-----------------------------
while ($string =~ s/\t+/' ' x (length($&) * 8 - length($`) % 8)/e) {
    # spin in empty loop until substitution finally fails
}
#-----------------------------
use Text::Tabs;
@expanded_lines  = expand(@lines_with_tabs);
@tabulated_lines = unexpand(@lines_without_tabs);
#-----------------------------
while (<>) {
    1 while s/\t+/' ' x (length($&) * 8 - length($`) % 8)/e;
    print;
}
#-----------------------------
use Text::Tabs;
$tabstop = 4;
while (<>) { print expand($_) }
#-----------------------------
use Text::Tabs;
while (<>) { print unexpand($_) }
#-----------------------------

