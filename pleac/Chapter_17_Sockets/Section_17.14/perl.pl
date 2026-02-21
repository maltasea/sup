
#-----------------------------
use Socket;

socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER, sockaddr_in($server_port, INADDR_ANY))
    or die "Binding: $!\n";

# accept loop
while (accept(CLIENT, SERVER)) {
    $my_socket_address = getsockname(CLIENT);
    ($port, $myaddr)   = sockaddr_in($my_socket_address);
}
#-----------------------------
$server = IO::Socket::INET->new(LocalPort => $server_port,
                                Type      => SOCK_STREAM,
                                Proto     => 'tcp',
                                Listen    => 10)
    or die "Can't create server socket: $@\n";

while ($client = $server->accept()) {
    $my_socket_address = $client->sockname();
    ($port, $myaddr)   = sockaddr_in($my_socket_address);
    # ...
}
#-----------------------------
use Socket;

$port = 4269;                       # port to bind to
$host = "specific.host.com";        # virtual host to listen on

socket(Server, PF_INET, SOCK_STREAM, getprotobyname("tcp"))
    or die "socket: $!";
bind(Server, sockaddr_in($port, inet_aton($host)))
    or die "bind: $!";
while ($client_address = accept(Client, Server)) {
    # ...
}
#-----------------------------

