
#-----------------------------
@ARGV = map { /\.(gz|Z)$/ ? "gzip -dc $_ |" : $_  } @ARGV;
while (<>) {
    # .......
} 
#-----------------------------
@ARGV = map { m#^\w+://# ? "GET $_ |" : $_ } @ARGV;
while (<>) {
    # .......
} 
#-----------------------------
$pwdinfo = `domainname` =~ /^(\(none\))?$/
                ? '< /etc/passwd'
                : 'ypcat  passwd |';

open(PWD, $pwdinfo)                 or die "can't open $pwdinfo: $!";
#-----------------------------
print "File, please? ";
chomp($file = <>);
open (FH, $file)                    or die "can't open $file: $!";
#-----------------------------

