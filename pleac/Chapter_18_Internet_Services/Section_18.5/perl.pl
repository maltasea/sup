
#-----------------------------
$pop = Net::POP3->new($mail_server)
    or die "Can't open connection to $mail_server : $!\n";
defined ($pop->login($username, $password))
    or die "Can't authenticate: $!\n";
$messages = $pop->list
    or die "Can't get list of undeleted messages: $!\n";
foreach $msgid (keys %$messages) {
    $message = $pop->get($msgid);
    unless (defined $message) {
        warn "Couldn't fetch $msgid from server: $!\n";
        next;
    }
    # $message is a reference to an array of lines
    $pop->delete($msgid);
}
#-----------------------------
$pop = Net::POP3->new( "pop.myisp.com" )
    or die "Can't connect to pop.myisp.com: $!\n";
#-----------------------------
$pop = Net::POP3->new( "pop.myisp.com",
                       Timeout => 30 )
    or die "Can't connect to pop.myisp.com : $!\n";
#-----------------------------
defined ($pop->login("gnat", "S33kr1T Pa55w0rD"))
    or die "Hey, my username and password didn't work!\n";

defined ($pop->login( "midget" ))           # use Net::Netrc to find password
    or die "Authentication failed.\n";

defined ($pop->
login())
                     # current username and Net::Netrc
    or die "Authentication failed.  Miserably.\n";
#-----------------------------
$pop->apop( $username, $password )
    or die "Couldn't authenticate: $!\n";
#-----------------------------
%undeleted = $pop->
list();

foreach $msgnum (keys %undeleted) {
    print "Message $msgnum is $undeleted{$msgnum} bytes long.\n";
}
#-----------------------------
print "Retrieving $msgnum : ";
$message = $pop->get($msgnum);
if ($message) {
    # succeeded
    print "\n";
    print @$message;                # print the message
} else {
        # failed
    print "failed ($!)\n";
}
#-----------------------------

