
#-----------------------------
use Net::Whois;

$domain_obj = Net::Whois::Domain->new($domain_name)
    or die "Couldn't get information on $domain_name: $!\n";

# call methods on $domain_obj to get name, tag, address, etc.
#-----------------------------
$d = Net::Whois::Domain->new( "perl.org" )
    or die "Can't get information on perl.org\n";
#-----------------------------
print "The domain is called ", $d->domain, "\n";
print "Its tag is ", $d->tag, "\n";
#-----------------------------
print "Mail for ", $d->name, " should be sent to:\n";
print map { "\t$_\n" } $d->address;
print "\t", $d->country, "\n";
#-----------------------------
$contact_hash = $d->contacts;
if ($contact_hash) {
    print "Contacts:\n";
    foreach $type (sort keys %$contact_hash) {
        print "  $type:\n";
        foreach $line (@{$contact_hash->{$type}}) {
            print "    $line\n";
        }
    }
} else {
    print "No contact information.\n";
}
#-----------------------------

