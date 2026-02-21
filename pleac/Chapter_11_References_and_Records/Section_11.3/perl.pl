
#-----------------------------
$href = \%hash;
$anon_hash = { "key1" => "value1", "key2" => "value2", ... };
$anon_hash_copy = { %hash };
#-----------------------------
%hash  = %$href;
$value = $href->{$key};
@slice = @$href{$key1, $key2, $key3};  # note: no arrow!
@keys  = keys %$href;
#-----------------------------
if (ref($someref) ne 'HASH') {
    die "Expected a hash reference, not $someref\n";
}
#-----------------------------
foreach $href ( \%ENV, \%INC ) {       # OR: for $href ( \(%ENV,%INC) ) {
    foreach $key ( keys %$href ) {
        print "$key => $href->{$key}\n";
    }
}
#-----------------------------
@values = @$hash_ref{"key1", "key2", "key3"};

for $val (@$hash_ref{"key1", "key2", "key3"}) {
    $val += 7;   # add 7 to each value in hash slice
} 
#-----------------------------

