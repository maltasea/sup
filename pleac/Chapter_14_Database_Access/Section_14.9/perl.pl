
#-----------------------------
use MLDBM 'DB_File';

my ($VARIABLE1,$VARIABLE2);
my $Persistent_Store = '/projects/foo/data';
BEGIN {
    my %data;
    tie(%data, 'MLDBM', $Persistent_Store)
        or die "Can't tie to $Persistent_Store : $!";
    $VARIABLE1 = $data{VARIABLE1};
    $VARIABLE2 = $data{VARIABLE2};
    # ...
    untie %data;
}
END {
    my %data;
    tie (%data, 'MLDBM', $Persistent_Store)
        or die "Can't tie to $Persistent_Store : $!";
    $data{VARIABLE1} = $VARIABLE1;
    $data{VARIABLE2} = $VARIABLE2;
    # ...
    untie %data;
}
#-----------------------------
push(@{$db{$user}}, $duration);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/mldbm_demo
#gnat        15.3
#tchrist     2.5
#jules       22.1
#tchrist     15.9
#gnat        8.7
#-----------------------------
use MLDBM qw(DB_File Storable);
#-----------------------------

