
#-----------------------------
@lines = <FILE>;
while ($line = pop @lines) {
    # do something with $line
}
#-----------------------------
@lines = reverse <FILE>;
foreach $line (@lines) {
    # do something with $line
}
#-----------------------------
for ($i = $#lines; $i != -1; $i--) {
    $line = $lines[$i];
}
#-----------------------------
# this enclosing block keeps local $/ temporary
{           
    local $/ = '';
    @paragraphs = reverse <FILE>;
}

foreach $paragraph (@paragraphs) {
    # do something
}
#-----------------------------

