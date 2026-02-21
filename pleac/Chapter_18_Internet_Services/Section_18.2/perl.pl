
#-----------------------------
use Net::FTP;

$ftp = Net::FTP->new("ftp.host.com")    or die "Can't connect: $@\n";
$ftp->login($username, $password)       or die "Couldn't login\n";
$ftp->cwd($directory)                   or die "Couldn't change directory\n";
$ftp->get($filename)                    or die "Couldn't get $filename\n";
$ftp->put($filename)                    or die "Couldn't put $filename\n";
#-----------------------------
$ftp = Net::FTP->new("ftp.host.com",
                     Timeout => 30,
                     Debug   => 1)
    or die "Can't connect: $@\n";
#-----------------------------
$ftp->
login()

    or die "Couldn't authenticate.\n";

$ftp->login($username)
    or die "Still couldn't authenticate.\n";

$ftp->login($username, $password)
    or die "Couldn't authenticate, even with explicit username
            and password.\n";

$ftp->login($username, $password, $account)
    or die "No dice.  It hates me.\n";
#-----------------------------
$ftp->put($localfile, $remotefile)
    or die "Can't send $localfile: $!\n";
#-----------------------------
$ftp->put(*STDIN, $remotefile)
    or die "Can't send from STDIN: $!\n";
#-----------------------------
$ftp->get($remotefile, $localfile)
    or die "Can't fetch $remotefile : $!\n";
#-----------------------------
$ftp->get($remotefile, *STDOUT)
    or die "Can't fetch $remotefile: $!\n";
#-----------------------------
$ftp->cwd("/pub/perl/CPAN/images/g-rated");
print "I'm in the directory ", $ftp->pwd(), "\n";
#-----------------------------
   $ftp->mkdir("/pub/gnat/perl", 1)
    or die "Can't create /pub/gnat/perl recursively: $!\n";
#-----------------------------
@lines = $ftp->ls("/pub/gnat/perl")
    or die "Can't get a list of files in /pub/gnat/perl: $!";
$ref_to_lines = $ftp->dir("/pub/perl/CPAN/src/latest.tar.gz")
    or die "Can't check status of latest.tar.gz: $!\n";
#-----------------------------
$ftp->quit()    or warn "Couldn't quit.  Oh well.\n";
#-----------------------------

