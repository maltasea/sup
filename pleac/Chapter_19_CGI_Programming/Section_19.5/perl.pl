
#-----------------------------
#Alias /perl/ /real/path/to/perl/scripts/
#
#<Location /perl>
#SetHandler  perl-script
#PerlHandler Apache::Registry
#Options ExecCGI
#</Location>
#
#PerlModule Apache::Registry
#PerlModule CGI
#PerlSendHeader On
#-----------------------------
#<Files *.perl>
#SetHandler  perl-script
#PerlHandler Apache::Registry
#Options ExecCGI
#</Files>
#-----------------------------

