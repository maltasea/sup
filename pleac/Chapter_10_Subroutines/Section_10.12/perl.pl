
#-----------------------------
die "some message";         # raise exception
#-----------------------------
eval { func() };
if ($@) {
    warn "func raised an exception: $@";
} 
#-----------------------------
eval { $val = func() };
warn "func blew up: $@" if $@;
#-----------------------------
eval { $val = func() };
if ($@ && $@ !~ /Full moon!/) {
    die;    # re-raise unknown errors
}
#-----------------------------
if (defined wantarray()) {
        return;
} else {
    die "pay attention to my error!";
}
#-----------------------------

