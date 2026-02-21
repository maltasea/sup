
#-----------------------------
head(100);
while (<>) {
    print;
} 

sub head {
    my $lines = shift || 20;
    return if $pid = open(STDOUT, "|-");
    die "cannot fork: $!" unless defined $pid;
    while (<STDIN>) {
        print;
        last unless --$lines ;
    } 
    exit;
} 
#-----------------------------
1: > Welcome to Linux, version 2.0.33 on a i686

2: > 

3: >     "The software required `Windows 95 or better', 

4: >      so I installed Linux."  
#-----------------------------
> 1: Welcome to Linux, Kernel version 2.0.33 on a i686

> 2: 

> 3:     "The software required `Windows 95 or better', 

> 4:      so I installed Linux."  
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/qnumcat
#-----------------------------

