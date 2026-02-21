
#-----------------------------
chomp($answer = <>);
if    ("SEND"  =~ /^\Q$answer/i) { print "Action is send\n"  }
elsif ("STOP"  =~ /^\Q$answer/i) { print "Action is stop\n"  }
elsif ("ABORT" =~ /^\Q$answer/i) { print "Action is abort\n" }
elsif ("LIST"  =~ /^\Q$answer/i) { print "Action is list\n"  }
elsif ("EDIT"  =~ /^\Q$answer/i) { print "Action is edit\n"  }
#-----------------------------
use Text::Abbrev;
$href = abbrev qw(send abort list edit);
for (print "Action: "; <>; print "Action: ") {
    chomp;
    my $action = $href->{ lc($_) };
    print "Action is $action\n";
}
#-----------------------------
$name = 'send';
&$name();
#-----------------------------
# assumes that &invoke_editor, &deliver_message,
# $file and $PAGER are defined somewhere else.
use Text::Abbrev;
my($href, %actions, $errors);
%actions = (
    "edit"  => \&invoke_editor,
    "send"  => \&deliver_message,
    "list"  => sub { system($PAGER, $file) },
    "abort" => sub {
                    print "See ya!\n";
                    exit;
               },
    ""      => sub {
                    print "Unknown command: $cmd\n";
                    $errors++;
               },
);

$href = abbrev(keys %actions);

local $_;
for (print "Action: "; <>; print "Action: ") {
    s/^\s+//;       # trim leading  white space
    s/\s+$//;       # trim trailing white space
    next unless $_;
    $actions->{ $href->{ lc($_) } }->();
}
#-----------------------------
$abbreviation = lc($_);
$expansion    = $href->{$abbreviation};
$coderef      = $actions->{$expansion};
&$coderef();
#-----------------------------

