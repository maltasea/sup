
#-----------------------------
use Net::Telnet;

$t = Net::Telnet->new( Timeout => 10,
                       Prompt  => '/%/',
                       Host    => $hostname );

$t->login($username, $password);
@files = $t->cmd("ls");
$t->print("top");
(undef, $process_string) = $t->waitfor('/\d+ processes/');
$t->close;
#-----------------------------
/[\$%#>] $/
#-----------------------------
$telnet = Net::Telnet->new( Errmode => sub { main::log(@_) }, ... );
#-----------------------------
$telnet->login($username, $password)
    or die "Login failed: @{[ $telnet->errmsg() ]}\n";
#-----------------------------
$telnet->waitfor('/--more--/')
#-----------------------------
$telnet->waitfor(String => 'greasy smoke', Timeout => 30)
#-----------------------------

