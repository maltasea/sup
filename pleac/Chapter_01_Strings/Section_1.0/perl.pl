
#-----------------------------
$string = '\n';                     # two characters, \ and an n
$string = 'Jon \'Maddog\' Orwant';  # literal single quotes
#-----------------------------
$string = "\n";                     # a "newline" character
$string = "Jon \"Maddog\" Orwant";  # literal double quotes
#-----------------------------
$string = q/Jon 'Maddog' Orwant/;   # literal single quotes
#-----------------------------
$string = q[Jon 'Maddog' Orwant];   # literal single quotes
$string = q{Jon 'Maddog' Orwant};   # literal single quotes
$string = q(Jon 'Maddog' Orwant);   # literal single quotes
$string = q<Jon 'Maddog' Orwant>;   # literal single quotes
#-----------------------------
$a = <<"EOF";
This is a multiline here document
terminated by EOF on a line by itself
EOF
#-----------------------------

