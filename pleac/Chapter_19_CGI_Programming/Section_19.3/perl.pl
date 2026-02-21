
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/webwhoami
#-----------------------------
#% perl -wc cgi-script        # just compilation
#
#% perl -w  cgi-script        # parms from stdin
#(offline mode: enter name=value pairs on standard input)
#
#name=joe
#
#number=10
#
#^D
#
#
#% perl -w  cgi-script name=joe number=10    # run with mock form input
#% perl -d  cgi-script name=joe number=10    # ditto, under the debugger
#
## POST method script in csh
#% (setenv HTTP_METHOD POST; perl -w cgi-script name=joe number=10)
## POST method script in sh
#% HTTP_METHOD=POST perl -w cgi-script name=joe number=10
#-----------------------------
#% perl -MCGI -le 'print CGI->VERSION'
#2.49
#-----------------------------
$| = 1;
#-----------------------------

