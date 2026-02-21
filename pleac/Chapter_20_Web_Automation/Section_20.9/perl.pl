
#-----------------------------
sub template {
    my ($filename, $fillings) = @_;
    my $text;
    local $/;                   # slurp mode (undef)
    local *F;                   # create local filehandle
    open(F, "< $filename\0")    || return;
    $text = <F>;                # read whole file
    close(F);                   # ignore retval
    # replace quoted words with value in %$fillings hash
    $text =~ s{ %% ( .*? ) %% }
              { exists( $fillings->{$1} )
                      ? $fillings->{$1}
                      : ""
              }gsex;
    return $text;
}
#-----------------------------
#<!-- simple.template for internal template() function -->
#<HTML><HEAD><TITLE>Report for %%username%%</TITLE></HEAD>
#<BODY><H1>Report for %%username%%</H1>
#%%username%% logged in %%count%% times, for a total of %%total%% minutes.
#-----------------------------
#<!-- fancy.template for Text::Template -->
#<HTML><HEAD><TITLE>Report for {$user}</TITLE></HEAD>
#<BODY><H1>Report for {$user}</H1>
#{ lcfirst($user) } logged in {$count} times, for a total of 
#{ int($total / 60) } minutes.
#-----------------------------
%fields = (
            username => $whats_his_name,
            count    => $login_count,
            total    => $minute_used,
);

print template("/home/httpd/templates/simple.template", \%fields);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/userrep
#-----------------------------
You owe: {$total}
#-----------------------------
The average was {$count ?  ($total/$count) : 0}.
#-----------------------------
# ^^INCLUDE^^ include/perl/ch20/userrep2
#-----------------------------

