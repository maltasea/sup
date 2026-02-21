
#-----------------------------
use DBI;


$dbh = DBI->connect('DBI:driver:database', 'username', 'auth',

            { RaiseError => 1, AutoCommit => 1});

$dbh->do($sql);

$sth = $dbh->prepare($sql);

$sth->execute();

while (@row = $sth->fetchrow_array) {

    # ...

}

$sth->finish();

$dbh->disconnect();
#-----------------------------
#disconnect(DBI::db=HASH(0x9df84)) invalidates 1 active cursor(s) 
#    at -e line 1.
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/dbusers
#-----------------------------

