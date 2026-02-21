
#-----------------------------
shutdown(SOCKET, 0);                # I/we have stopped reading data
shutdown(SOCKET, 1);                # I/we have stopped writing data
shutdown(SOCKET, 2);                # I/we have stopped using this socket
#-----------------------------
$socket->shutdown(0);               # I/we have stopped reading data
#-----------------------------
print SERVER "my request\n";        # send some data
shutdown(SERVER, 1);                # send eof; no more writing
$answer = <SERVER>;                 # but you can still read
#-----------------------------

