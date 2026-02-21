
#-----------------------------
print ol( li([ qw(red blue green)]) );
# <OL><LI>red</LI> <LI>blue</LI> <LI>green</LI></OL>

@names = qw(Larry Moe Curly);
print ul( li({ -TYPE => "disc" }, \@names) );
# <UL><LI TYPE="disc">Larry</LI> <LI TYPE="disc">Moe</LI>
#
#     <LI TYPE="disc">Curly</LI></UL>
#-----------------------------
print li("alpha");
#     <LI>alpha</LI>

print li( [ "alpha", "omega"] );
#     <LI>alpha</LI> <LI>omega</LI>
#-----------------------------
use CGI qw(:standard :html3);

%hash = (
    "Wisconsin"  => [ "Superior", "Lake Geneva", "Madison" ],
    "Colorado"   => [ "Denver", "Fort Collins", "Boulder" ],
    "Texas"      => [ "Plano", "Austin", "Fort Stockton" ],
    "California" => [ "Sebastopol", "Santa Rosa", "Berkeley" ],
);

$\ = "\n";

print "<TABLE> <CAPTION>Cities I Have Known</CAPTION>";
print Tr(th [qw(State Cities)]);
for $k (sort keys %hash) {
    print Tr(th($k), td( [ sort @{$hash{$k}} ] ));
}
print "</TABLE>";
#-----------------------------
# <TABLE> <CAPTION>Cities I Have Known</CAPTION>
# 
#     <TR><TH>State</TH> <TH>Cities</TH></TR>
# 
#     <TR><TH>California</TH> <TD>Berkeley</TD> <TD>Santa Rosa</TD> 
# 
# 	  <TD>Sebastopol</TD> </TR>
# 
#     <TR><TH>Colorado</TH> <TD>Boulder</TD> <TD>Denver</TD> 
# 
# 	  <TD>Fort Collins</TD> </TR>
# 
#     <TR><TH>Texas</TH> <TD>Austin</TD> <TD>Fort Stockton</TD> 
# 
# 	  <TD>Plano</TD></TR>
# 
#     <TR><TH>Wisconsin</TH> <TD>Lake Geneva</TD> <TD>Madison</TD> 
# 
# 	  <TD>Superior</TD></TR>
# 
# </TABLE>
#-----------------------------
print table
        caption('Cities I have Known'),
        Tr(th [qw(State Cities)]),
        map { Tr(th($_), td( [ sort @{$hash{$_}} ] )) } sort keys %hash;
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/salcheck
#-----------------------------

