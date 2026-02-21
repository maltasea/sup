
#-----------------------------
use Sys::Hostname;

$hostname = hostname();
#-----------------------------
use POSIX qw(uname);
($kernel, $hostname, $release, $version, $hardware) = uname();

$hostname = (uname)[1];             # or just one
#-----------------------------
use Socket;                         # for AF_INET
$address  = gethostbyname($hostname)
    or die "Couldn't resolve $hostname : $!";
$hostname = gethostbyaddr($address, AF_INET)
    or die "Couldn't re-resolve $hostname : $!";
#-----------------------------

