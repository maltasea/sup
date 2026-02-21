
#-----------------------------
# first open and exclusively lock the file
open(FH, ">>/tmp/formlog")              or die "can't append to formlog: $!";
flock(FH, 2)                            or die "can't flock formlog: $!";

# either using the procedural interface
use CGI qw(:standard);
save_parameters(*FH);                   # with CGI::save

# or using the object interface
use CGI;
$query = CGI->new();
$query->save(*FH);

close(FH)                               or die "can't close formlog: $!";
#-----------------------------
use CGI qw(:standard);
open(MAIL, "|/usr/lib/sendmail -oi -t") or die "can't fork sendmail: $!";
print MAIL <<EOF;
From: $0 (your cgi script)
To: hisname\@hishost.com
Subject: mailed form submission

EOF
save_parameters(*MAIL);
close(MAIL)                             or die "can't close sendmail: $!"; 
#-----------------------------
param("_timestamp", scalar localtime);
param("_environs", %ENV);
#-----------------------------
use CGI;
open(FORMS, "< /tmp/formlog")       or die "can't read formlog: $!";
flock(FORMS, 1)                     or die "can't lock formlog: $!";
while ($query = CGI->new(*FORMS)) {
    last unless $query->param();     # means end of file
    %his_env = $query->param('_environs');
    $count  += $query->param('items requested')
                unless $his_env{REMOTE_HOST} =~ /(^|\.)perl\.com$/
}
print "Total orders: $count\n";
#-----------------------------

