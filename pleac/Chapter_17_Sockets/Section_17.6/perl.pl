
#-----------------------------
use IO::Socket;

unlink "/tmp/mysock";
$server = IO::Socket::UNIX->new(Local     => "/tmp/mysock",
                                Type      => SOCK_DGRAM,
                                Listen    => 5 )
    or die $@;

$client = IO::Socket::UNIX->new(Peer       => "/tmp/mysock",
                                Type      => SOCK_DGRAM,
                                Timeout   => 10 )
    or die $@;
#-----------------------------
use Socket;
    
socket(SERVER, PF_UNIX, SOCK_STREAM, 0);
unlink "/tmp/mysock";
bind(SERVER, sockaddr_un("/tmp/mysock"))
    or die "Can't create server: $!";

socket(CLIENT, PF_UNIX, SOCK_STREAM, 0);
connect(CLIENT, sockaddr_un("/tmp/mysock"))
    or die "Can't connect to /tmp/mysock: $!";
#-----------------------------

