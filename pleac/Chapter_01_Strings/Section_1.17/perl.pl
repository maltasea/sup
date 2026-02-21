
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/fixstyle
#analysed        => analyzed
#built-in        => builtin
#chastized       => chastised
#commandline     => command-line
#de-allocate     => deallocate
#dropin          => drop-in
#hardcode        => hard-code
#meta-data       => metadata
#multicharacter  => multi-character
#multiway        => multi-way
#non-empty       => nonempty
#non-profit      => nonprofit
#non-trappable   => nontrappable
#pre-define      => predefine
#preextend       => pre-extend
#re-compiling    => recompiling
#reenter         => re-enter
#turnkey         => turn-key
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/fixstyle2
#analysed        => analyzed
#built-in        => builtin
#chastized       => chastised
#commandline     => command-line
#de-allocate     => deallocate
#dropin          => drop-in
#hardcode        => hard-code
#meta-data       => metadata
#multicharacter  => multi-character
#multiway        => multi-way
#non-empty       => nonempty
#non-profit      => nonprofit
#non-trappable   => nontrappable
#pre-define      => predefine
#preextend       => pre-extend
#re-compiling    => recompiling
#reenter         => re-enter
#turnkey         => turn-key
#-----------------------------
# very fast, but whitespace collapse
while (<>) { 
    for (split) { 
        print $change{$_} || $_, " ";
    }
    print "\n";
}
#-----------------------------
my $pid = open(STDOUT, "|-");
die "cannot fork: $!" unless defined $pid;
unless ($pid) {             # child
        while (<STDIN>) {
        s/ $//;
        print;
    }
    exit;
}
#-----------------------------

