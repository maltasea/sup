
#-----------------------------
BEGIN {
    unless (@ARGV == 2 && (2 == grep {/^\d+$/} @ARGV)) {
        die "usage: $0 num1 num2\n";
    }
}
use Some::Module;
use More::Modules;
#-----------------------------
if ($opt_b) {
    require Math::BigInt;
}
#-----------------------------
use Fcntl qw(O_EXCL O_CREAT O_RDWR);
#-----------------------------
require Fcntl;
Fcntl->import(qw(O_EXCL O_CREAT O_RDWR));
#-----------------------------
sub load_module {
    require $_[0];  #WRONG
    import  $_[0];  #WRONG
}
#-----------------------------
load_module('Fcntl', qw(O_EXCL O_CREAT O_RDWR));

sub load_module {
    eval "require $_[0]";
    die if $@;
    $_[0]->import(@_[1 .. $#_]);
}
#-----------------------------
use autouse Fcntl => qw( O_EXCL() O_CREAT() O_RDWR() );
#-----------------------------

