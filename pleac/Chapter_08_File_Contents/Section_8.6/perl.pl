
#-----------------------------
srand;
rand($.) < 1 && ($line = $_) while <>;
# $line is the random line
#-----------------------------
$/ = "%%\n";
@ARGV = qw( /usr/share/games/fortunes );
srand;
rand($.) < 1 && ($adage = $_) while <>;
print $adage;
#-----------------------------

