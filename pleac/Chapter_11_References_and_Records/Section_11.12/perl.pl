
#-----------------------------
use Storable;

$r2 = dclone($r1);
#-----------------------------
@original = ( \@a, \@b, \@c );
@surface = @original;
#-----------------------------
@deep = map { [ @$_ ] } @original;
#-----------------------------
use Storable qw(dclone); 
$r2 = dclone($r1);
#-----------------------------
%newhash = %{ dclone(\%oldhash) };
#-----------------------------

