
#-----------------------------
# given $RECORD with field separated by PATTERN,
# extract @FIELDS.
@FIELDS = split(/PATTERN/, $RECORD);
#-----------------------------
split(/([+-])/, "3+5-2");
#-----------------------------
(3, '+', 5, '-', 2)
#-----------------------------
@fields = split(/:/, $RECORD);
#-----------------------------
@fields = split(/\s+/, $RECORD);
#-----------------------------
@fields = split(" ", $RECORD);
#-----------------------------

