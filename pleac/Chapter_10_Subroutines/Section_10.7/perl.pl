
#-----------------------------
thefunc(INCREMENT => "20s", START => "+5m", FINISH => "+30m");
thefunc(START => "+5m", FINISH => "+30m");
thefunc(FINISH => "+30m");
thefunc(START => "+5m", INCREMENT => "15s");
#-----------------------------
sub thefunc {
    my %args = ( 
        INCREMENT   => '10s', 
        FINISH      => 0, 
        START       => 0, 
        @_,         # argument pair list goes here
    );
    if ($args{INCREMENT}  =~ /m$/ ) { ..... }
} 
#-----------------------------

