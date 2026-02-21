
#-----------------------------
use Socket;

$packed_ip   = inet_aton("208.146.240.1");
$socket_name = sockaddr_in($port, $packed_ip);
#-----------------------------
use Socket;

$socket_name = sockaddr_un("/tmp/mysock");
#-----------------------------
($port, $packed_ip) = sockaddr_in($socket_name);    # for PF_INET sockets
($filename)         = sockaddr_un($socket_name);    # for PF_UNIX sockets
#-----------------------------
$ip_address = inet_ntoa($packed_ip);
$packed_ip  = inet_aton("204.148.40.9");
$packed_ip  = inet_aton("www.oreilly.com");
#-----------------------------

