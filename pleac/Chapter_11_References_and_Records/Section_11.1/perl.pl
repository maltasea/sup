
#-----------------------------
$aref               = \@array;
$anon_array         = [1, 3, 5, 7, 9];
$anon_copy          = [ @array ];
@$implicit_creation = (2, 4, 6, 8, 10);
#-----------------------------
push(@$anon_array, 11);
#-----------------------------
$two = $implicit_creation->[0];
#-----------------------------
$last_idx  = $#$aref;
$num_items = @$aref;
#-----------------------------
$last_idx  = $#{ $aref };
$num_items = scalar @{ $aref };
#-----------------------------
# check whether $someref contains a simple array reference
if (ref($someref) ne 'ARRAY') {
    die "Expected an array reference, not $someref\n";
}

print "@{$array_ref}\n";        # print original data

@order = sort @{ $array_ref };  # sort it

push @{ $array_ref }, $item;    # append new element to orig array  
#-----------------------------
sub array_ref {
    my @array;
    return \@array;
}

$aref1 = array_ref();
$aref2 = array_ref();
#-----------------------------
print $array_ref->[$N];         # access item in position N (best)
print $$array_ref[$N];          # same, but confusing
print ${$array_ref}[$N];        # same, but still confusing, and ugly to boot
#-----------------------------
@$pie[3..5];                    # array slice, but a little confusing to read
@{$pie}[3..5];                  # array slice, easier (?) to read
#-----------------------------
@{$pie}[3..5] = ("blackberry", "blueberry", "pumpkin");
#-----------------------------
$sliceref = \@{$pie}[3..5];     # WRONG!
#-----------------------------
foreach $item ( @{$array_ref} ) {   
    # $item has data
}

for ($idx = 0; $idx <= $#{ $array_ref }; $idx++) {  
    # $array_ref->[$idx] has data
}
#-----------------------------

