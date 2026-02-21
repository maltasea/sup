
#-----------------------------
#!/usr/bin/perl -T
open(FH, "> $ARGV[0]") or die;
#-----------------------------
# Insecure dependency in open while running with -T switch at ...
#-----------------------------
$file = $ARGV[0];                                   # $file tainted
unless ($file =~ m#^([\w.-]+)$#) {                  # $1 is untainted
    die "filename '$file' has invalid characters.\n";
}
$file = $1;                                         # $file untainted
#-----------------------------
unless (-e $filename) {                     # WRONG!
    open(FH, "> $filename");
    # ...
}
#-----------------------------

