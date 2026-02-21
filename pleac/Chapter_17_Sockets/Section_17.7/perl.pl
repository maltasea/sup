
#-----------------------------
use Socket;

$other_end         = getpeername(SOCKET)
    or die "Couldn't identify other end: $!\n";
($port, $iaddr)    = unpack_sockaddr_in($other_end);
$ip_address        = inet_ntoa($iaddr);
#-----------------------------
use Socket;

$other_end        = getpeername(SOCKET)
    or die "Couldn't identify other end: $!\n";
($port, $iaddr)   = unpack_sockaddr_in($other_end);
$actual_ip        = inet_ntoa($iaddr);
$claimed_hostname = gethostbyaddr($iaddr, AF_INET);
@name_lookup      = gethostbyname($claimed_hostname)
    or die "Could not look up $claimed_hostname : $!\n";
@resolved_ips     = map { inet_ntoa($_) }
    @name_lookup[ 4 .. $#ips_for_hostname ];
#-----------------------------
$packed_ip  = gethostbyname($name) or die "Couldn't look up $name : $!\n";
$ip_address = inet_ntoa($packed_ip);
#-----------------------------

