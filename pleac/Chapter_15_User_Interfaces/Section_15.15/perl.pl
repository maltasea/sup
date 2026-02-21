
#-----------------------------
use Tk::DialogBox;

$dialog = $main->DialogBox( -title   => "Register This Program",
                            -buttons => [ "Register", "Cancel" ] );

# add widgets to the dialog box with $dialog->Add()

# later, when you need to display the dialog box
$button = $dialog->Show();
if ($button eq "Register") {
    # ...
} elsif ($button eq "Cancel") {
    # ...
} else {
    # this shouldn't happen
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch15/tksample3
#-----------------------------
# ^^INCLUDE^^ include/perl/ch15/tksample4
#-----------------------------

