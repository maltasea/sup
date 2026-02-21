
#-----------------------------
while (<CONFIG>) {
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    $User_Preferences{$var} = $value;
} 
#-----------------------------
do "$ENV{HOME}/.progrc";
#-----------------------------
# set class C net
NETMASK = 255.255.255.0
MTU     = 296
    
DEVICE  = cua1
RATE    = 115200
MODE    = adaptive
#-----------------------------
no strict 'refs';
$$var = $value;
#-----------------------------
# set class C net
$NETMASK = '255.255.255.0';
$MTU     = 0x128;
# Brent, please turn on the modem
$DEVICE  = 'cua1';
$RATE    = 115_200;
$MODE    = 'adaptive';
#-----------------------------
if ($DEVICE =~ /1$/) {
    $RATE =  28_800;
} else {
    $RATE = 115_200;
} 
#-----------------------------
$APPDFLT = "/usr/local/share/myprog";

do "$APPDFLT/sysconfig.pl";
do "$ENV{HOME}/.myprogrc";
#-----------------------------
do "$ENV{HOME}/.myprogrc";
    or
do "$APPDFLT/sysconfig.pl"
#-----------------------------
{ package Settings; do "$ENV{HOME}/.myprogrc" }
#-----------------------------
eval `cat $ENV{HOME}/.myprogrc`;
#-----------------------------
$file = "someprog.pl";
unless ($return = do $file) {
    warn "couldn't parse $file: $@"         if $@;
    warn "couldn't do $file: $!"            unless defined $return;
    warn "couldn't run $file"               unless $return;
}
#-----------------------------

