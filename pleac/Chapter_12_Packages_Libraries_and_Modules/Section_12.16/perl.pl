
#-----------------------------
#=head2 Discussion
#
#If we had a I<.h> file with function prototype declarations, we
#could include that, but since we're writing this one from scratch,
#we'll use the B<-c> flag to omit building code to translate any
#C<#define> symbols. The B<-n> flag says to create a module directory
#named I<FineTime/>, which will have the following files.
#-----------------------------
#=for troff
#.EQ
#log sub n (x) = { {log sub e (x)} over {log sub e (n)} }
#.EN
#-----------------------------
#=for later
#next if 1 .. ?^$?;
#s/^(.)/>$1/;
#s/(.{73})........*/$1<SNIP>/;
#
#=cut back to perl
#-----------------------------
#=begin comment
#
#if (!open(FILE, $file)) {
#    unless ($opt_q) {  #)
#        warn "$me: $file: $!\n";
#        $Errors++;
#    }
#    next FILE;
#}
#
#$total = 0;
#$matches = 0;
#
#=end comment
#-----------------------------

