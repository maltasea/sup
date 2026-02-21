
#-----------------------------
do {
    print "Pattern? ";
    chomp($pat = <>);
    eval { "" =~ /$pat/ };
    warn "INVALID PATTERN $@" if $@;
} while $@;
#-----------------------------
sub is_valid_pattern {
    my $pat = shift;
    return eval { "" =~ /$pat/; 1 } || 0;
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/paragrep
#-----------------------------
$pat = "You lose @{[ system('rm -rf *')]} big here";
#-----------------------------
$safe_pat = quotemeta($pat);
something() if /$safe_pat/;
#-----------------------------
something() if /\Q$pat/;
#-----------------------------

