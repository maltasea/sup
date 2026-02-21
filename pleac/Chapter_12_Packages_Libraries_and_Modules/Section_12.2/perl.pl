
#-----------------------------
# no import
BEGIN {
    unless (eval "require $mod") {
        warn "couldn't load $mod: $@";
    }
}

# imports into current package
BEGIN {
    unless (eval "use $mod") {
        warn "couldn't load $mod: $@";
    }
}
#-----------------------------
BEGIN {
    my($found, @DBs, $mod);
    $found = 0;
    @DBs = qw(Giant::Eenie Giant::Meanie Mouse::Mynie Moe);
    for $mod (@DBs) {
        if (eval "require $mod") {
            $mod->
import
();         # if needed
            $found = 1;
            last;
        }
    }
    die "None of @DBs loaded" unless $found;
}
#-----------------------------

