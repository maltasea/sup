
#-----------------------------
use LWP::Simple;
use URI::URL;

my $url = url('http://www.perl.com/cgi-bin/cpan_mod');
$url->query_form(module => 'DB_File', readme => 1);
$content = get($url);
#-----------------------------
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

$ua = LWP::UserAgent->new();
my $req = POST 'http://www.perl.com/cgi-bin/cpan_mod',
               [ module => 'DB_File', readme => 1 ];
$content = $ua->request($req)->as_string;
#-----------------------------
field1=value1&field2=value2&field3=value3
#-----------------------------
http://www.site.com/path/to/
script.cgi?field1=value1&field2=value2&field3=value3
#-----------------------------
http://www.site.com/path/to/
script.cgi?arg=%22this+isn%27t+%3CEASY%3E+%26+%3CFUN%3E%22
#-----------------------------
$ua->proxy(['http', 'ftp'] => 'http://proxy.myorg.com:8081');
#-----------------------------

