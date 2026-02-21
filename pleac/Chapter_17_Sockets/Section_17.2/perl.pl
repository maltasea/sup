
#-----------------------------
use IO::Socket;

$server = IO::Socket::INET->new(LocalPort => $server_port,
                                Type      => SOCK_STREAM,
                                Reuse     => 1,
                                Listen    => 10 )   # or SOMAXCONN
    or die "Couldn't be a tcp server on port $server_port : $@\n";

while ($client = $server->accept()) {
    # $client is the new connection
}

close($server);
#-----------------------------
use Socket;

# make the socket
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

# so we can restart our server quickly
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);

# build up my socket address
$my_addr = sockaddr_in($server_port, INADDR_ANY);
bind(SERVER, $my_addr)
    or die "Couldn't bind to port $server_port : $!\n";

# establish a queue for incoming connections
listen(SERVER, SOMAXCONN)
    or die "Couldn't listen on port $server_port : $!\n";

# accept and process connections
while (accept(CLIENT, SERVER)) {
    # do something with CLIENT
}

close(SERVER);
#-----------------------------
use Socket;

while ($client_address = accept(CLIENT, SERVER)) {
    ($port, $packed_ip) = sockaddr_in($client_address);
    $dotted_quad = inet_ntoa($packed_ip);
    # do as thou wilt
}
#-----------------------------
while ($client = $server->accept()) {
    # ...
}
#-----------------------------
while (($client,$client_address) = $server->accept()) {
    # ...
}
#-----------------------------
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

$flags = fcntl(SERVER, F_GETFL, 0)
            or die "Can't get flags for the socket: $!\n";

$flags = fcntl(SERVER, F_SETFL, $flags | O_NONBLOCK)
            or die "Can't set flags for the socket: $!\n";
#-----------------------------

