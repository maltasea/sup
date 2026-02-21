
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/hiweb
#-----------------------------
use CGI qw(:standard);
$who   = param("Name");
$phone = param("Number");
@picks = param("Choices");
#-----------------------------
print header( -TYPE    => 'text/plain',
              -EXPIRES => '+3d' );
#-----------------------------

