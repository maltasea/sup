
#-----------------------------
@a = (1, 3, 5, 6, 7, 8);
@b = (2, 3, 5, 7, 9);

@union = @isect = @diff = ();
%union = %isect = ();
%count = ();
#-----------------------------
foreach $e (@a) { $union{$e} = 1 }

foreach $e (@b) {
    if ( $union{$e} ) { $isect{$e} = 1 }
    $union{$e} = 1;
}
@union = keys %union;
@isect = keys %isect;
#-----------------------------
foreach $e (@a, @b) { $union{$e}++ && $isect{$e}++ }

@union = keys %union;
@isect = keys %isect;
#-----------------------------
foreach $e (@a, @b) { $count{$e}++ }

foreach $e (keys %count) {
    push(@union, $e);
    if ($count{$e} == 2) {
        push @isect, $e;
    } else {
        push @diff, $e;
    }
}
#-----------------------------
@isect = @diff = @union = ();

foreach $e (@a, @b) { $count{$e}++ }

foreach $e (keys %count) {
    push(@union, $e);
    push @{ $count{$e} == 2 ? \@isect : \@diff }, $e;
}
#-----------------------------

