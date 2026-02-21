
#-----------------------------
sub commify_series {
    (@_ == 0) ? ''                                      :
    (@_ == 1) ? $_[0]                                   :
    (@_ == 2) ? join(" and ", @_)                       :
                join(", ", @_[0 .. ($#_-1)], "and $_[-1]");
}
#-----------------------------
@array = ("red", "yellow", "green");
print "I have ", @array, " marbles.\n";
print "I have @array marbles.\n";
I have redyellowgreen marbles.

I have red yellow green marbles.
#-----------------------------
# ^^INCLUDE^^ include/perl/ch04/commify_series
#-----------------------------
#The list is: just one thing.
#
#The list is: Mutt and Jeff.
#
#The list is: Peter, Paul, and Mary.
#
#The list is: To our parents, Mother Theresa, and God.
#
#The list is: pastrami, ham and cheese, peanut butter and jelly, and tuna.
#
#The list is: recycle tired, old phrases and ponder big, happy thoughts.
#
#The list is: recycle tired, old phrases; ponder 
#
#   big, happy thoughts; and sleep and dream peacefully.
#-----------------------------

