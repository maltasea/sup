
#-----------------------------
use LWP::RobotUA;
$ua = LWP::RobotUA->new('websnuffler/0.1', 'me@wherever.com');
#-----------------------------
403 (Forbidden) Forbidden by robots.txt
#-----------------------------
#% GET http://www.webtechniques.com/robots.txt 
#User-agent: *
#
#     Disallow: /stats
#
#     Disallow: /db
#
#     Disallow: /logs
#
#     Disallow: /store
#
#     Disallow: /forms
#
#     Disallow: /gifs
#
#     Disallow: /wais-src
#
#     Disallow: /scripts
#
#     Disallow: /config
#-----------------------------
#% GET http://www.cnn.com/robots.txt | head
## robots, scram
#
## $I d : robots.txt,v 1.2 1998/03/10 18:27:01 mreed Exp $
#
#User-agent: *
#
#Disallow: /
#
#User-agent:     Mozilla/3.01 (hotwired-test/0.1)
#
#Disallow:   /cgi-bin
#
#Disallow:   /TRANSCRIPTS
#
#Disallow:   /development
#-----------------------------

