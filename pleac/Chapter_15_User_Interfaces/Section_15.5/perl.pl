
#-----------------------------
use Term::ANSIColor;

print color("red"), "Danger, Will Robinson!\n", color("reset");
print "This is just normal text.\n";
print colored("<BLINK>Do you hurt yet?</BLINK>", "blink");
#-----------------------------
use Term::ANSIColor qw(:constants);

print RED, "Danger, Will Robinson!\n", RESET;
#-----------------------------
# rhyme for the deadly coral snake
print color("red on_black"),  "venom lack\n";
print color("red on_yellow"), "kill that fellow\n";

print color("green on_cyan blink"), "garish!\n";
print color("reset");
#-----------------------------
print colored("venom lack\n", "red", "on_black");
print colored("kill that fellow\n", "red", "on_yellow");

print colored("garish!\n", "green", "on_cyan", "blink");
#-----------------------------
use Term::ANSIColor qw(:constants);

print BLACK, ON_WHITE, "black on white\n";
print WHITE, ON_BLACK, "white on black\n";
print GREEN, ON_CYAN, BLINK, "garish!\n";
print RESET;
#-----------------------------
END { print color("reset") }
#-----------------------------
$Term::ANSIColor::EACHLINE = $/;
print colored(<<EOF, RED, ON_WHITE, BOLD, BLINK);
This way
each line
has its own
attribute set.
EOF
#-----------------------------

