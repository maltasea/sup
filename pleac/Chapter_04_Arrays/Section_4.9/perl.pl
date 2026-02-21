
#-----------------------------
# push
push(@ARRAY1, @ARRAY2);
#-----------------------------
@ARRAY1 = (@ARRAY1, @ARRAY2);
#-----------------------------
@members = ("Time", "Flies");
@initiates = ("An", "Arrow");
push(@members, @initiates);
# @members is now ("Time", "Flies", "An", "Arrow")
#-----------------------------
splice(@members, 2, 0, "Like", @initiates);
print "@members\n";
splice(@members, 0, 1, "Fruit");
splice(@members, -2, 2, "A", "Banana");
print "@members\n";
#-----------------------------
Time Flies Like An Arrow

Fruit Flies Like A Banana
#-----------------------------

