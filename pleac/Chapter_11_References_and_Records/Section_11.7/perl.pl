
#-----------------------------
$c1 = mkcounter(20); 
$c2 = mkcounter(77);

printf "next c1: %d\n", $c1->{NEXT}->();  # 21 
printf "next c2: %d\n", $c2->{NEXT}->();  # 78 
printf "next c1: %d\n", $c1->{NEXT}->();  # 22 
printf "last c1: %d\n", $c1->{PREV}->();  # 21 
printf "old  c2: %d\n", $c2->{RESET}->(); # 77
#-----------------------------
sub mkcounter {
    my $count  = shift; 
    my $start  = $count; 
    my $bundle = { 
        "NEXT"   => sub { return ++$count  }, 
        "PREV"   => sub { return --$count  }, 
        "GET"    => sub { return $count    },
        "SET"    => sub { $count = shift   }, 
        "BUMP"   => sub { $count += shift  }, 
        "RESET"  => sub { $count = $start  },
    }; 
    $bundle->{"LAST"} = $bundle->{"PREV"}; 
    return $bundle;
}
#-----------------------------

