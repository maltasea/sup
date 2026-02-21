
#-----------------------------
chomp($pattern = <CONFIG_FH>);
if ( $data =~ /$pattern/ ) { ..... }
#-----------------------------
/ALPHA|BETA/;
#-----------------------------
/^(?=.*ALPHA)(?=.*BETA)/s;
#-----------------------------
/ALPHA.*BETA|BETA.*ALPHA/s;
#-----------------------------
/^(?:(?!PAT).)*$/s;
#-----------------------------
/(?=^(?:(?!BAD).)*$)GOOD/s;
#-----------------------------
if (!($string =~ /pattern/)) { something() }   # ugly
if (  $string !~ /pattern/)  { something() }   # preferred
#-----------------------------
if ($string =~ /pat1/ && $string =~ /pat2/ ) { 
something
() }
#-----------------------------
if ($string =~ /pat1/ || $string =~ /pat2/ ) { 
something
() }
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/minigrep
#-----------------------------
 "labelled" =~ /^(?=.*bell)(?=.*lab)/s
#-----------------------------
$string =~ /bell/ && $string =~ /lab/
#-----------------------------
 if ($murray_hill =~ m{
             ^              # start of string
            (?=             # zero-width lookahead
                .*          # any amount of intervening stuff
                bell        # the desired bell string
            )               # rewind, since we were only looking
            (?=             # and do the same thing
                .*          # any amount of intervening stuff
                lab         # and the lab part
            )
         }sx )              # /s means . can match newline
{
    print "Looks like Bell Labs might be in Murray Hill!\n";
}
#-----------------------------
"labelled" =~ /(?:^.*bell.*lab)|(?:^.*lab.*bell)/
#-----------------------------
$brand = "labelled";
if ($brand =~ m{
        (?:                 # non-capturing grouper
            ^ .*?           # any amount of stuff at the front
              bell          # look for a bell
              .*?           # followed by any amount of anything
              lab           # look for a lab
          )                 # end grouper
    |                       # otherwise, try the other direction
        (?:                 # non-capturing grouper
            ^ .*?           # any amount of stuff at the front
              lab           # look for a lab
              .*?           # followed by any amount of anything
              bell          # followed by a bell
          )                 # end grouper
    }sx )                   # /s means . can match newline
{
    print "Our brand has bell and lab separate.\n";
}
#-----------------------------
$map =~ /^(?:(?!waldo).)*$/s
#-----------------------------
if ($map =~ m{
        ^                   # start of string
        (?:                 # non-capturing grouper
            (?!             # look ahead negation
                waldo       # is he ahead of us now?
            )               # is so, the negation failed
            .               # any character (cuzza /s)
        ) *                 # repeat that grouping 0 or more
        $                   # through the end of the string
    }sx )                   # /s means . can match newline
{
    print "There's no waldo here!\n";
}
#-----------------------------
 7:15am  up 206 days, 13:30,  4 users,  load average: 1.04, 1.07, 1.04

USER     TTY      FROM              LOGIN@  IDLE   JCPU   PCPU  WHAT

tchrist  tty1                       5:16pm 36days 24:43   0.03s  xinit

tchrist  tty2                       5:19pm  6days  0.43s  0.43s  -tcsh

tchrist  ttyp0    chthon            7:58am  3days 23.44s  0.44s  -tcsh

gnat     ttyS4    coprolith         2:01pm 13:36m  0.30s  0.30s  -tcsh
#-----------------------------
#% w | minigrep '^(?!.*ttyp).*tchrist'
#-----------------------------
m{
    ^                       # anchored to the start
    (?!                     # zero-width look-ahead assertion
        .*                  # any amount of anything (faster than .*?)
        ttyp                # the string you don't want to find
    )                       # end look-ahead negation; rewind to start
    .*                      # any amount of anything (faster than .*?)
    tchrist                 # now try to find Tom
}x
#-----------------------------
#% w | grep tchrist | grep -v ttyp
#-----------------------------
#% grep -i 'pattern' files
#% minigrep '(?i)pattern' files
#-----------------------------

