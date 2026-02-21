
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/dummyhttpd
#-----------------------------
#http://somewhere.com/cgi-bin/whatever
#-----------------------------
#http://somewhere.com:8989/cgi-bin/whatever
#-----------------------------
#% telnet www.perl.com 80
#GET /bogotic HTTP/1.0
#
#<blank line here>
#
#HTTP/1.1 404 File Not Found
#
#Date: Tue, 21 Apr 1998 11:25:43 GMT
#
#Server: Apache/1.2.4
#
#Connection: close
#
#Content-Type: text/html
#
#
#<HTML><HEAD>
#
#<TITLE>404 File Not Found</TITLE>
#
#</HEAD><BODY>
#
#<H1>File Not Found</H1>
#
#The requested URL /bogotic was not found on this server.<P>
#
#</BODY></HTML>
#-----------------------------
% GET -esuSU http://mox.perl.com/perl/bogotic
# GET http://language.perl.com/bogotic
# 
# Host: mox.perl.com
# 
# User-Agent: lwp-request/1.32
# 
# 
# GET http://mox.perl.com/perl/bogotic --> 302 Moved Temporarily
# 
# GET http://www.perl.com/perl/bogotic --> 302 Moved Temporarily
# 
# GET http://language.perl.com/bogotic --> 404 File Not Found
# 
# Connection: close
# 
# Date: Tue, 21 Apr 1998 11:29:03 GMT
# 
# Server: Apache/1.2.4
# 
# Content-Type: text/html
# 
# Client-Date: Tue, 21 Apr 1998 12:29:01 GMT
# 
# Client-Peer: 208.201.239.47:80
# 
# Title: Broken perl.com Links
# 
# 
# <HTML>
# 
# <HEAD><TITLE>An Error Occurred</TITLE></HEAD>
# 
# <BODY>
# 
# <H1>An Error Occurred</h1>
# 
# 404 File Not Found
# 
# </BODY>
# 
# </HTML>
#-----------------------------

