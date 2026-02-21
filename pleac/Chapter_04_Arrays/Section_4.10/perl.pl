
#-----------------------------
# reverse @ARRAY into @REVERSED
@REVERSED = reverse @ARRAY;
#-----------------------------
for ($i = $#ARRAY; $i >= 0; $i--) {
    # do something with $ARRAY[$i]
}
#-----------------------------
# two-step: sort then reverse
@ascending = sort { $a cmp $b } @users;
@descending = reverse @ascending;

# one-step: sort with reverse comparison
@descending = sort { $b cmp $a } @users;
#-----------------------------

