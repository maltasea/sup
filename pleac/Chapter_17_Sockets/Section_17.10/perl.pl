
#-----------------------------
# ^^INCLUDE^^ include/perl/ch17/biclient
#-----------------------------
my $byte;
while (sysread($handle, $byte, 1) == 1) {
    print STDOUT $byte;
}
#-----------------------------

