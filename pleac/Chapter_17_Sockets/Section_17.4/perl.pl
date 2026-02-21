
#-----------------------------
use Socket;
socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp")) 
    or die "socket: $!";
#-----------------------------
use IO::Socket;
$handle = IO::Socket::INET->new(Proto => 'udp') 
    or die "socket: $@";     # yes, it uses $@ here
#-----------------------------
$ipaddr   = inet_aton($HOSTNAME);
$portaddr = sockaddr_in($PORTNO, $ipaddr);
send(SOCKET, $MSG, 0, $portaddr) == length($MSG)
        or die "cannot send to $HOSTNAME($PORTNO): $!";
#-----------------------------
$portaddr = recv(SOCKET, $MSG, $MAXLEN, 0)      or die "recv: $!";
($portno, $ipaddr) = sockaddr_in($portaddr);
$host = gethostbyaddr($ipaddr, AF_INET);
print "$host($portno) said $MSG\n";
#-----------------------------
send(MYSOCKET, $msg_buffer, $flags, $remote_addr)
    or die "Can't send: $!\n";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch17/clockdrift
#-----------------------------

