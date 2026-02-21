
#-----------------------------
use Net::NNTP;

$server = Net::NNTP->new("news.host.dom")
    or die "Can't connect to news server: $@\n";
($narticles, $first, $last, $name) = $server->group( "misc.test" )
    or die "Can't select misc.test\n";
$headers  = $server->head($first)
    or die "Can't get headers from article $first in $name\n";
$bodytext = $server->body($first)
    or die "Can't get body from article $first in $name\n";
$article  = $server->article($first)
    or die "Can't get article $first from $name\n";

$server->
postok()

    or warn "Server didn't tell me I could post.\n";

$server->post( [ @lines ] )
    or die "Can't post: $!\n";
#-----------------------------
<0401@jpl-devvax.JPL.NASA.GOV>
#-----------------------------
$server = Net::NNTP->new("news.mycompany.com")
    or die "Couldn't connect to news.mycompany.com: $@\n";
#-----------------------------
$grouplist = $server->
list()

    or die "Couldn't fetch group list\n";

foreach $group (keys %$grouplist) {
    if ($grouplist->{$group}->[2] eq 'y') {
        # I can post to $group
    }
}
#-----------------------------
($narticles, $first, $last, $name) = $server->group("comp.lang.perl.misc")
    or die "Can't select comp.lang.perl.misc\n";
#-----------------------------
@lines = $server->article($message_id)
    or die "Can't fetch article $message_id: $!\n";
#-----------------------------
@group = $server->group("comp.lang.perl.misc")
    or die "Can't select group comp.lang.perl.misc\n";
@lines = $server->head($group[1])
    or die "Can't get headers from first article in comp.lang.perl.misc\n";
#-----------------------------
$server->post(@message)
    or die "Can't post\n";
#-----------------------------
unless ($server->
postok()
) {
    warn "You may not post.\n";
}
#-----------------------------

