
#-----------------------------
my @common = ();
foreach (keys %hash1) {
    push(@common, $_) if exists $hash2{$_};
}
# @common now contains common keys
#-----------------------------
my @this_not_that = ();
foreach (keys %hash1) {
    push(@this_not_that, $_) unless exists $hash2{$_};
}
#-----------------------------
# %food_color per the introduction

# %citrus_color is a hash mapping citrus food name to its color.
%citrus_color = ( Lemon  => "yellow",
                  Orange => "orange",
                  Lime   => "green" );

# build up a list of non-citrus foods
@non_citrus = ();

foreach (keys %food_color) {
    push (@non_citrus, $_) unless exists $citrus_color{$_};
}
#-----------------------------

