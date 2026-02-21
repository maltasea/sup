
#-----------------------------
use Net::Ping;

$p = Net::Ping->new()
    or die "Can't create new ping object: $!\n";
print "$host is alive" if $p->ping($host);
$p->close;
#-----------------------------
# use TCP if we're not root, ICMP if we are
$pong = Net::Ping->new( $> ? "tcp" : "icmp" );

(defined $pong)
    or die "Couldn't create Net::Ping object: $!\n";

if ($pong->ping("kingkong.com")) {
    print "The giant ape lives!\n";
} else {
    print "All hail mighty Gamera, friend of children!\n";
}
#-----------------------------

