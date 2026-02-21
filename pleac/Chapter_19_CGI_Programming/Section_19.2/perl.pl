
#-----------------------------
use CGI::Carp;
warn "This is a complaint";
die "But this one is serious";
#-----------------------------
BEGIN {
    use CGI::Carp qw(carpout);
    open(LOG, ">>/var/local/cgi-logs/mycgi-log")
        or die "Unable to append to mycgi-log: $!\n";
    carpout(*LOG);
}
#-----------------------------
use CGI::Carp qw(fatalsToBrowser);
die "Bad error here";
#-----------------------------

