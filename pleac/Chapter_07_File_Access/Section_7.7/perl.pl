
#-----------------------------
while (<>) {
    # do something with the line
}
#-----------------------------
while (<>) {
    # ...
 }
#-----------------------------
unshift(@ARGV, '-') unless @ARGV;
while ($ARGV = shift @ARGV) {
    unless (open(ARGV, $ARGV)) {
        warn "Can't open $ARGV: $!\n";
        next;
    }
    while (defined($_ = <ARGV>)) {
        # ...
    }
}
#-----------------------------
@ARGV = glob("*.[Cch]") unless @ARGV;
#-----------------------------
# arg demo 1: Process optional -c flag 
if (@ARGV && $ARGV[0] eq '-c') { 
    $chop_first++;
    shift;
}

# arg demo 2: Process optional -NUMBER flag    
if (@ARGV && $ARGV[0] =~ /^-(\d+)$/) { 
    $columns = $1; 
    shift;
}

# arg demo 3: Process clustering -a, -i, -n, or -u flags     
while (@ARGV && $ARGV[0] =~ /^-(.+)/ && (shift, ($_ = $1), 1)) { 
    next if /^$/; 
    s/a// && (++$append,      redo);
    s/i// && (++$ignore_ints, redo); 
    s/n// && (++$nostdout,    redo); 
    s/u// && (++$unbuffer,    redo); 
    die "usage: $0 [-ainu] [filenames] ...\n";    
}
#-----------------------------
undef $/;		     
while (<>) { 	
    # $_ now has the complete contents of 	
    # the file whose name is in $ARGV     
}
#-----------------------------
{     # create block for local 	
    local $/;         # record separator now undef 	
    while (<>) { 	    
        # do something; called functions still have 	    
        # undeffed version of $/ 	
    }     
}                     # $/ restored here
#-----------------------------
while (<>) { 	
    print "$ARGV:$.:$_"; 	
    close ARGV if eof;     
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/findlogin1
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/findlogin2
#-----------------------------
#% perl -ne 'print if /login/'
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/lowercase1
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/lowercase2
#-----------------------------
#% perl -Mlocale -pe 's/([^\W0-9_])/\l$1/g'
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/countchunks
#-----------------------------
#+0894382237
#less /etc/motd
#+0894382239
#vi ~/.exrc
#+0894382242
#date
#+0894382242
#who
#+0894382288
#telnet home
#-----------------------------
#% perl -pe 's/^#\+(\d+)\n/localtime($1) . " "/e' 
#Tue May  5 09:30:37 1998     less /etc/motd 
#
#Tue May  5 09:30:39 1998     vi ~/.exrc 
#
#Tue May  5 09:30:42 1998     date
#
#Tue May  5 09:30:42 1998     who 
#
#Tue May  5 09:31:28 1998     telnet home
#-----------------------------

