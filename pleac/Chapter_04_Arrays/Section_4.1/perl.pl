
#-----------------------------
@a = ("quick", "brown", "fox");
#-----------------------------
@a = qw(Why are you teasing me?);
#-----------------------------
@lines = (<<"END_OF_HERE_DOC" =~ m/^\s*(.+)/gm);
    The boy stood on the burning deck,
    It was as hot as glass.
END_OF_HERE_DOC
#-----------------------------
@bigarray = ();
open(DATA, "< mydatafile")       or die "Couldn't read from datafile: $!\n";
while (<DATA>) {
    chomp;
    push(@bigarray, $_);
}
#-----------------------------
$banner = 'The Mines of Moria';
$banner = q(The Mines of Moria);
#-----------------------------
$name   =  "Gandalf";
$banner = "Speak, $name, and enter!";
$banner = qq(Speak, $name, and welcome!);
#-----------------------------
$his_host   = 'www.perl.com';
$host_info  = `nslookup $his_host`; # expand Perl variable

$perl_info  = qx(ps $$);            # that's Perl's $$
$shell_info = qx'ps $$';            # that's the new shell's $$
#-----------------------------
@banner = ('Costs', 'only', '$4.95');
@banner = qw(Costs only $4.95);
@banner = split(' ', 'Costs only $4.95');
#-----------------------------
@brax   = qw! ( ) < > { } [ ] !;
@rings  = qw(Nenya Narya Vilya);
@tags   = qw<LI TABLE TR TD A IMG H1 P>;
@sample = qw(The vertical bar (|) looks and behaves like a pipe.);
#-----------------------------
@banner = qw|The vertical bar (\|) looks and behaves like a pipe.|;
#-----------------------------
@ships  = qw(Niña Pinta Santa María);               # WRONG
@ships  = ('Niña', 'Pinta', 'Santa María');         # right
#-----------------------------

