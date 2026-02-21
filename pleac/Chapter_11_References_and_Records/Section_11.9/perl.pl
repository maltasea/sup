
#-----------------------------
$record = {
    NAME   => "Jason",
    EMPNO  => 132,
    TITLE  => "deputy peon",
    AGE    => 23,
    SALARY => 37_000,
    PALS   => [ "Norbert", "Rhys", "Phineas"],
};

printf "I am %s, and my pals are %s.\n",
    $record->{NAME},
    join(", ", @{$record->{PALS}});
#-----------------------------
# store record
$byname{ $record->{NAME} } = $record;

# later on, look up by name
if ($rp = $byname{"Aron"}) {        # false if missing
    printf "Aron is employee %d.\n", $rp->{EMPNO};
}

# give jason a new pal
push @{$byname{"Jason"}->{PALS}}, "Theodore";
printf "Jason now has %d pals\n", scalar @{$byname{"Jason"}->{PALS}};
#-----------------------------
# Go through all records
while (($name, $record) = each %byname) {
    printf "%s is employee number %d\n", $name, $record->{EMPNO};
}
#-----------------------------
# store record
$employees[ $record->{EMPNO} ] = $record;

# lookup by id
if ($rp = $employee[132]) {
    printf "employee number 132 is %s\n", $rp->{NAME};
}
#-----------------------------
$byname{"Jason"}->{SALARY} *= 1.035;
#-----------------------------
@peons   = grep { $_->{TITLE} =~ /peon/i } @employees;
@tsevens = grep { $_->{AGE}   == 27 }      @employees;
#-----------------------------
# Go through all records
foreach $rp (sort { $a->{AGE} <=> $b->{AGE} } values %byname) {
    printf "%s is age %d.\n", $rp->{NAME}, $rp->{AGE};
    # or with a hash slice on the reference
    printf "%s is employee number %d.\n", @$rp{'NAME','EMPNO'};
}
#-----------------------------
# use @byage, an array of arrays of records
push @{ $byage[ $record->{AGE} ] }, $record;
#-----------------------------
for ($age = 0; $age <= $#byage; $age++) {
    next unless $byage[$age];
    print "Age $age: ";
    foreach $rp (@{$byage[$age]}) {
        print $rp->{NAME}, " ";
    }
    print "\n";
}
#-----------------------------
for ($age = 0; $age <= $#byage; $age++) {
    next unless $byage[$age];
    printf "Age %d: %s\n", $age,
        join(", ", map {$_->{NAME}} @{$byage[$age]});

}
#-----------------------------

