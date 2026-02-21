
#-----------------------------
$num  = ord($char);
$char = chr($num);
#-----------------------------
$char = sprintf("%c", $num);                # slower than chr($num)
printf("Number %d is character %c\n", $num, $num);
Number 101 is character e
#-----------------------------
@ASCII = unpack("C*", $string);
$STRING = pack("C*", @ascii);
#-----------------------------
$ascii_value = ord("e");    # now 101
$character   = chr(101);    # now "e"
#-----------------------------
printf("Number %d is character %c\n", 101, 101);
#-----------------------------
@ascii_character_numbers = unpack("C*", "sample");
print "@ascii_character_numbers\n";
115 97 109 112 108 101


$word = pack("C*", @ascii_character_numbers);
$word = pack("C*", 115, 97, 109, 112, 108, 101);   # same
print "$word\n";
sample
#-----------------------------
$hal = "HAL";
@ascii = unpack("C*", $hal);
foreach $val (@ascii) {
    $val++;                 # add one to each ASCII value
}
$ibm = pack("C*", @ascii);
print "$ibm\n";             # prints "IBM"
#-----------------------------

