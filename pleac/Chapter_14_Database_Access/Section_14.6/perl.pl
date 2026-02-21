
#-----------------------------
use DB_File;

# specify the Perl sub to do key comparison using the
# exported $DB_BTREE hash reference
$DB_BTREE->{'compare'} = sub {
    my ($key1, $key2) = @_ ;
    return "\L$key1" cmp "\L$key2";
};

tie(%hash, "DB_File", $filename, O_RDWR|O_CREAT, 0666, $DB_BTREE)
    or die "can't tie $filename: $!";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/sortdemo
#-----------------------------
#by           6
#
#camp         4
#
#Can't        1
#
#down         5
#
#Gibraltar    7
#
#go           3
#
#you          2
#-----------------------------
tie(%hash, "DB_File", undef, O_RDWR|O_CREAT, 0666, $DB_BTREE)
        or die "can't tie: $!";
#-----------------------------

