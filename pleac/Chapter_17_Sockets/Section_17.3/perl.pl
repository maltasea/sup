
#-----------------------------
print SERVER "What is your name?\n";
chomp ($response = <SERVER>);
#-----------------------------
defined (send(SERVER, $data_to_send, $flags))
    or die "Can't send : $!\n";

recv(SERVER, $data_read, $maxlen, $flags)
    or die "Can't receive: $!\n";
#-----------------------------
use IO::Socket;

$server->send($data_to_send, $flags)
    or die "Can't send: $!\n";

$server->recv($data_read, $flags)
    or die "Can't recv: $!\n";
#-----------------------------
use IO::Select;

$select = IO::Select->new();
$select->add(*FROM_SERVER);
$select->add($to_client);

@read_from = $select->can_read($timeout);
foreach $socket (@read_from) {
    # read the pending data from $socket
}
#-----------------------------
use Socket;
require "sys/socket.ph";    # for &TCP_NODELAY

setsockopt(SERVER, SOL_SOCKET, &TCP_NODELAY, 1)
    or die "Couldn't disable Nagle's algorithm: $!\n";
#-----------------------------
setsockopt(SERVER, SOL_SOCKET, &TCP_NODELAY, 0)
    or die "Couldn't enable Nagle's algorithm: $!\n";
#-----------------------------
$rin = '';                          # initialize bitmask
vec($rin, fileno(SOCKET), 1) = 1;   # mark SOCKET in $rin
# repeat calls to vec() for each socket to check

$timeout = 10;                      # wait ten seconds

$nfound = select($rout = $rin, undef, undef, $timeout);
if (vec($rout, fileno(SOCKET),1)){
    # data to be read on SOCKET
}
#-----------------------------

