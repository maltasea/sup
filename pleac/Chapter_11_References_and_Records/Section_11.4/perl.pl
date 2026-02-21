
#-----------------------------
$cref = \&func;
$cref = sub { ... };
#-----------------------------
@returned = $cref->(@arguments);
@returned = &$cref(@arguments);
#-----------------------------
$funcname = "thefunc";
&$funcname();
#-----------------------------
my %commands = (
    "happy" => \&joy,
    "sad"   => \&sullen,
    "done"  => sub { die "See ya!" },
    "mad"   => \&angry,
);

print "How are you? ";
chomp($string = <STDIN>);
if ($commands{$string}) {
    $commands{$string}->();
} else {
    print "No such command: $string\n";
} 
#-----------------------------
sub counter_maker {
    my $start = 0;
    return sub {                      # this is a closure
        return $start++;              # lexical from enclosing scope
    };
}

$counter = counter_maker();

for ($i = 0; $i < 5; $i ++) {
    print &$counter, "\n";
}
#-----------------------------
$counter1 = counter_maker();
$counter2 = counter_maker();

for ($i = 0; $i < 5; $i ++) {
    print &$counter1, "\n";
}

print &$counter1, " ", &$counter2, "\n";
0

1

2

3

4

5 0
#-----------------------------
sub timestamp {
    my $start_time = time(); 
    return sub { return time() - $start_time };
} 
$early = timestamp(); 
sleep 20; 
$later = timestamp(); 
sleep 10;
printf "It's been %d seconds since early.\n", $early->();
printf "It's been %d seconds since later.\n", $later->();
#It's been 30 seconds since early.
#
#It's been 10 seconds since later.
#-----------------------------

