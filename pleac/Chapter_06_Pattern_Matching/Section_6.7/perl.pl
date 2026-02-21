
#-----------------------------
undef $/;
@chunks = split(/pattern/, <FILEHANDLE>);
#-----------------------------
# .Ch, .Se and .Ss divide chunks of STDIN
{
    local $/ = undef;
    @chunks = split(/^\.(Ch|Se|Ss)$/m, <>);
}
print "I read ", scalar(@chunks), " chunks.\n";
#-----------------------------

