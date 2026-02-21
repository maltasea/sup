
#-----------------------------
exec("archive *.data")
    or die "Couldn't replace myself with archive: $!\n";
#-----------------------------
exec("archive", "accounting.data")
    or die "Couldn't replace myself with archive: $!\n";
#-----------------------------
exec("archive accounting.data")
    or die "Couldn't replace myself with archive: $!\n";
#-----------------------------

