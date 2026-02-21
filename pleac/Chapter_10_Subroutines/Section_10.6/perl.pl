
#-----------------------------
if (wantarray()) {
    # list context
} 
elsif (defined wantarray()) {
    # scalar context
} 
else {
    # void context
} 
#-----------------------------
if (wantarray()) {
    print "In list context\n";
    return @many_things;
} elsif (defined wantarray()) {
    print "In scalar context\n";
    return $one_thing;
} else {
    print "In void context\n";
    return;  # nothing
}

mysub();                    # void context

$a = mysub();               # scalar context
if (mysub()) {  }           # scalar context

@a = mysub();               # list context
print mysub();              # list context
#-----------------------------

