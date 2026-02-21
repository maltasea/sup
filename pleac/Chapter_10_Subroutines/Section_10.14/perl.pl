
#-----------------------------
undef &grow;                # silence -w complaints of redefinition
*grow = \&expand;           
grow();                     # calls expand()

{
    local *grow = \&shrink;         # only until this block exists
        grow();                 # calls shrink()
}
#-----------------------------
*one::var = \%two::Table;   # make %one::var alias for %two::Table
*one::big = \&two::small;   # make &one::big alias for &two::small
#-----------------------------
local *fred = \&barney;     # temporarily alias &fred to &barney
#-----------------------------
$string =  red("careful here");
print $string;
<FONT COLOR='red'>careful here</FONT>
#-----------------------------
sub red { "<FONT COLOR='red'>@_</FONT>" }
#-----------------------------
sub color_font {
    my $color = shift;
    return "<FONT COLOR='$color'>@_</FONT>";
}
sub red    { color_font("red", @_)     }
sub green  { color_font("green", @_)   }
sub blue   { color_font("blue", @_)    }
sub purple { color_font("purple", @_)  }
# etc
#-----------------------------
@colors = qw(red blue green yellow orange purple violet);
for my $name (@colors) {
    no strict 'refs';
    *$name = sub { "<FONT COLOR='$name'>@_</FONT>" };
} 
#-----------------------------
*$name = sub ($) { "<FONT COLOR='$name'>$_[0]</FONT>" };
#-----------------------------

