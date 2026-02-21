
#-----------------------------
#% perl -i.orig -p -e 'FILTER COMMAND' file1 file2 file3 ...
#-----------------------------
#!/usr/bin/perl -i.orig -p
# filter commands go here
#-----------------------------
#% perl -pi.orig -e 's/DATE/localtime/e'
#-----------------------------
while (<>) {
    if ($ARGV ne $oldargv) {           # are we at the next file?
        rename($ARGV, $ARGV . '.orig');
        open(ARGVOUT, ">$ARGV");       # plus error check
        select(ARGVOUT);
        $oldargv = $ARGV;
    }
    s/DATE/localtime/e;
}
continue{
    print;
}
select (STDOUT);                      # restore default output
#-----------------------------
#Dear Sir/Madam/Ravenous Beast,
#    As of DATE, our records show your account
#is overdue.  Please settle by the end of the month.
#Yours in cheerful usury,
#    --A. Moneylender
#-----------------------------
#Dear Sir/Madam/Ravenous Beast,
#    As of Sat Apr 25 12:28:33 1998, our records show your account
#is overdue.  Please settle by the end of the month.
#Yours in cheerful usury,
#    --A. Moneylender
#-----------------------------
#% perl -i.old -pe 's{\bhisvar\b}{hervar}g' *.[Cchy]
#-----------------------------
# set up to iterate over the *.c files in the current directory,
# editing in place and saving the old file with a .orig extension
local $^I   = '.orig';              # emulate  -i.orig
local @ARGV = glob("*.c");          # initialize list of files
while (<>) {
    if ($. == 1) {
        print "This line should appear at the top of each file\n";
    }
    s/\b(p)earl\b/${1}erl/ig;       # Correct typos, preserving case
    print;
} continue {close ARGV if eof} 
#-----------------------------

