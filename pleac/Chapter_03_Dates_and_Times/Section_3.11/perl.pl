
#-----------------------------
use Date::Manip qw(ParseDate DateCalc);
$d1 = ParseDate("Tue, 26 May 1998 23:57:38 -0400");
$d2 = ParseDate("Wed, 27 May 1998 05:04:03 +0100");
print DateCalc($d1, $d2);
# +0:0:0:0:0:6:25
#-----------------------------
# ^^INCLUDE^^ include/perl/ch03/hopdelta
#-----------------------------
# Sender               Recipient            Time                   Delta
# 
# Start                wall.org             09:17:12 1998/05/23
# 
# wall.org             mail.brainstorm.net  09:20:56 1998/05/23    44s   3m
# 
# mail.brainstorm.net  jhereg.perl.com      09:20:58 1998/05/23     2s
#  
#-----------------------------

