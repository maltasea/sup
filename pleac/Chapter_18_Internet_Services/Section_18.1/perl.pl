
#-----------------------------
use Socket;

@addresses = gethostbyname($name)   or die "Can't resolve $name: $!\n";
@addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
# @addresses is a list of IP addresses ("208.201.239.48", "208.201.239.49")
#-----------------------------
use Socket;

$address = inet_ntoa(inet_aton($name));
# $address is a single IP address "208.201.239.48"
#-----------------------------
use Socket;

$name = gethostbyaddr(inet_aton($address), AF_INET)
            or die "Can't resolve $address: $!\n";
# $name is the hostname ("www.perl.com")
#-----------------------------
use Socket;
$packed_address = inet_aton("208.146.140.1");
$ascii_address  = inet_ntoa($packed_address);
#-----------------------------
$packed = gethostbyname($hostname)
            or die "Couldn't resolve address for $hostname: $!\n";
$address = inet_ntoa($packed);
print "I will use $address as the address for $hostname\n";
#-----------------------------
# $address is the IP address I'm checking, like "128.138.243.20"
use Socket;
$name    = gethostbyaddr(inet_aton($address), AF_INET)
                or die "Can't look up $address : $!\n";
@addr    = gethostbyname($name)
                or die "Can't look up $name : $!\n";
$found   = grep { $address eq inet_ntoa($_) } @addr[4..$#addr];
#-----------------------------
# ^^INCLUDE^^ include/perl/ch18/mxhost
#-----------------------------
#% mxhost cnn.com
#10 mail.turner.com
#
#30 alfw2.turner.com
#-----------------------------
# ^^INCLUDE^^ include/perl/ch18/hostaddrs
#-----------------------------
#% hostaddrs www.ora.com
#helio.ora.com => 204.148.40.9
#
#
#% hostaddrs www.whitehouse.gov
#www.whitehouse.gov => 198.137.240.91 198.137.240.92
#-----------------------------

