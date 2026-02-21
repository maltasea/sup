
#-----------------------------
$url = "http://www.perl.com/CPAN/";
print "Location: $url\n\n";
exit;
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/oreobounce
#-----------------------------
#Status: 302 Moved Temporarily
#
#Set-Cookie: filling=vanilla%20cr%E4me; domain=.perl.com; 
#
#    expires=Tue, 21-Jul-1998 11:58:55 GMT
#
#Date: Tue, 21 Apr 1998 11:55:55 GMT
#
#Location: http://somewhere.perl.com/nonesuch.html
#
#Content-Type: text/html
#
#B<<blank line here>>
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/os_snipe
#-----------------------------
use CGI qw(:standard);
print header( -STATUS => '204 No response' );
#-----------------------------
#Status: 204 No response
#
#Content-Type: text/html
#
#<blank line here>
#-----------------------------
#!/bin/sh

cat <<EOCAT
Status: 204 No response
 
EOCAT
#-----------------------------

