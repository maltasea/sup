
#-----------------------------
%father = ( 'Cain'      => 'Adam',
            'Abel'      => 'Adam',
            'Seth'      => 'Adam',
            'Enoch'     => 'Cain',
            'Irad'      => 'Enoch',
            'Mehujael'  => 'Irad',
            'Methusael' => 'Mehujael',
            'Lamech'    => 'Methusael',
            'Jabal'     => 'Lamech',
            'Jubal'     => 'Lamech',
            'Tubalcain' => 'Lamech',
            'Enos'      => 'Seth' );
#-----------------------------
while (<>) {
    chomp;
    do {
        print "$_ ";        # print the current name
        $_ = $father{$_};   # set $_ to $_'s father
    } while defined;        # until we run out of fathers
    print "\n";
}
#-----------------------------
while ( ($k,$v) = each %father ) {
    push( @{ $children{$v} }, $k );
}

$" = ', ';                  # separate output with commas
while (<>) {
    chomp;
    if ($children{$_}) {
        @children = @{$children{$_}};
    } else {
        @children = "nobody";
    }
    print "$_ begat @children.\n";
}
#-----------------------------
foreach $file (@files) {
    local *F;               # just in case we want a local FH
    unless (open (F, "<$file")) {
        warn "Couldn't read $file: $!; skipping.\n";
        next;
    }
    
    while (<F>) {
        next unless /^\s*#\s*include\s*<([^>]+)>/;
        push(@{$includes{$1}}, $file);
    }
    close F;
}
#-----------------------------
@include_free = ();                 # list of files that don't include others
@uniq{map { @$_ } values %includes} = undef;
foreach $file (sort keys %uniq) {
        push( @include_free , $file ) unless $includes{$file};
}
#-----------------------------

