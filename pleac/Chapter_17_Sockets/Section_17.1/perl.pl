
#-----------------------------
use IO::Socket;

$socket = IO::Socket::INET->new(PeerAddr => $remote_host,
                                PeerPort => $remote_port,
                                Proto    => "tcp",
                                Type     => SOCK_STREAM)
    or die "Couldn't connect to $remote_host:$remote_port : $@\n";

# ... do something with the socket
print $socket "Why don't you call me anymore?\n";

$answer = <$socket>;

# and terminate the connection when we're done
close($socket);
#-----------------------------
use Socket;

# create a socket
socket(TO_SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

# build the address of the remote machine
$internet_addr = inet_aton($remote_host)
    or die "Couldn't convert $remote_host into an Internet address: $!\n";
$paddr = sockaddr_in($remote_port, $internet_addr);

# connect
connect(TO_SERVER, $paddr)
    or die "Couldn't connect to $remote_host:$remote_port : $!\n";

# ... do something with the socket
print TO_SERVER "Why don't you call me anymore?\n";

# and terminate the connection when we're done
close(TO_SERVER);
#-----------------------------
$client = IO::Socket::INET->new("www.yahoo.com:80")
    or die $@;
#-----------------------------
$s = IO::Socket::INET->new(PeerAddr => "Does not Exist",
                           Peerport => 80,
                           Type     => SOCK_STREAM )
    or die $@;
#-----------------------------
$s = IO::Socket::INET->new(PeerAddr => "bad.host.com",
                           PeerPort => 80,
                           Type     => SOCK_STREAM,
                           Timeout  => 5 )
    or die $@;
#-----------------------------
$inet_addr = inet_aton("208.146.240.1");
$paddr     = sockaddr_in($port, $inet_addr);
bind(SOCKET, $paddr)         or die "bind: $!";
#-----------------------------
$inet_addr = gethostbyname("www.yahoo.com")
                            or die "Can't resolve www.yahoo.com: $!";
$paddr     = sockaddr_in($port, $inet_addr);
bind(SOCKET, $paddr)        or die "bind: $!";
#-----------------------------

