
#-----------------------------
# all in one
($var = <<HERE_TARGET) =~ s/^\s+//gm;
    your text
    goes here
HERE_TARGET

# or with two steps
$var = <<HERE_TARGET;
    your text
    goes here
HERE_TARGET
$var =~ s/^\s+//gm;
#-----------------------------
($definition = <<'FINIS') =~ s/^\s+//gm;
    The five varieties of camelids
    are the familiar camel, his friends
    the llama and the alpaca, and the
    rather less well-known guanaco
    and vicuña.
FINIS
#-----------------------------
sub fix {
    my $string = shift;
    $string =~ s/^\s+//gm;
    return $string;
}

print fix(<<"END");
    My stuff goes here
END

# With function predeclaration, you can omit the parens:
print fix <<"END";
    My stuff goes here
END
#-----------------------------
($quote = <<'    FINIS') =~ s/^\s+//gm;
        ...we will have peace, when you and all your works have
        perished--and the works of your dark master to whom you would
        deliver us. You are a liar, Saruman, and a corrupter of mens
        hearts.  --Theoden in /usr/src/perl/taint.c
    FINIS
$quote =~ s/\s+--/\n--/;      #move attribution to line of its own
#-----------------------------
if ($REMEMBER_THE_MAIN) {
    $perl_main_C = dequote<<'    MAIN_INTERPRETER_LOOP';
        @@@ int
        @@@ runops() {
        @@@     SAVEI32(runlevel);
        @@@     runlevel++;
        @@@     while ( op = (*op->op_ppaddr)() ) ;
        @@@     TAINT_NOT;
        @@@     return 0;
        @@@ }
    MAIN_INTERPRETER_LOOP
    # add more code here if you want
}
#-----------------------------
sub dequote;
$poem = dequote<<EVER_ON_AND_ON;
       Now far ahead the Road has gone,
          And I must follow, if I can,
       Pursuing it with eager feet,
          Until it joins some larger way
       Where many paths and errands meet.
          And whither then? I cannot say.
                --Bilbo in /usr/src/perl/pp_ctl.c
EVER_ON_AND_ON
print "Here's your poem:\n\n$poem\n";
#-----------------------------
#Here's your poem:  
#
#Now far ahead the Road has gone,
#
#   And I must follow, if I can,
#
#Pursuing it with eager feet,
#
#   Until it joins some larger way
#
#Where many paths and errands meet.
#
#   And whither then? I cannot say.
#
#	  --Bilbo in /usr/src/perl/pp_ctl.c
#-----------------------------
sub dequote {
    local $_ = shift;
    my ($white, $leader);  # common whitespace and common leading string
    if (/^\s*(?:([^\w\s]+)(\s*).*\n)(?:\s*\1\2?.*\n)+$/) {
        ($white, $leader) = ($2, quotemeta($1));
    } else {
        ($white, $leader) = (/^(\s+)/, '');
    }
    s/^\s*?$leader(?:$white)?//gm;
    return $_;
}
#-----------------------------
    if (m{
            ^                       # start of line
            \s *                    # 0 or more whitespace chars
            (?:                     # begin first non-remembered grouping
                 (                  #   begin save buffer $1
                    [^\w\s]         #     one byte neither space nor word
                    +               #     1 or more of such
                 )                  #   end save buffer $1
                 ( \s* )            #   put 0 or more white in buffer $2
                 .* \n              #   match through the end of first line
             )                      # end of first grouping
             (?:                    # begin second non-remembered grouping
                \s *                #   0 or more whitespace chars
                \1                  #   whatever string is destined for $1
                \2 ?                #   what'll be in $2, but optionally
                .* \n               #   match through the end of the line
             ) +                    # now repeat that group idea 1 or more
             $                      # until the end of the line
          }x
       )
    {
        ($white, $leader) = ($2, quotemeta($1));
    } else {
        ($white, $leader) = (/^(\s+)/, '');
    }
    s{
         ^                          # start of each line (due to /m)
         \s *                       # any amount of leading whitespace
            ?                       #   but minimally matched
         $leader                    # our quoted, saved per-line leader
         (?:                        # begin unremembered grouping
            $white                  #    the same amount
         ) ?                        # optionalize in case EOL after leader
    }{}xgm;
#-----------------------------

