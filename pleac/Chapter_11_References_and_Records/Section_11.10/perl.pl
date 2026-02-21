
#-----------------------------
FieldName: Value
#-----------------------------
foreach $record (@Array_of_Records) { 
    for $key (sort keys %$record) {
        print "$key: $record->{$key}\n";
    } 
    print "\n";
}
#-----------------------------
$/ = "";                # paragraph read mode
while (<>) {
    my @fields = split /^([^:]+):\s*/m;
    shift @fields;      # for leading null field
    push(@Array_of_Records, { map /(.*)/, @fields });
} 
#-----------------------------

