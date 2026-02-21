
#-----------------------------
use IO::Socket;
$server = IO::Socket::INET->new(LocalPort => $server_port,
                                Proto     => "udp")
    or die "Couldn't be a udp server on port $server_port : $@\n";
#-----------------------------
while ($him = $server->recv($datagram, $MAX_TO_READ, $flags)) {
    # do something
} 
#-----------------------------
# ^^INCLUDE^^ include/perl/ch17/udpqofd
#-----------------------------
# ^^INCLUDE^^ include/perl/ch17/udpmsg
#-----------------------------

