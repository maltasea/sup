
#-----------------------------
use DB_File;

tie(@array, "DB_File", "/tmp/textfile", O_RDWR|O_CREAT, 0666, $DB_RECNO)
    or die "Cannot open file 'text': $!\n" ;

$array[4] = "a new line";
untie @array;
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/recno_demo
#-----------------------------
#ORIGINAL
#
#0: zero
#
#1: one
#
#2: two
#
#3: three
#
#4: four
#
#
#The last record was [four]
#
#The first record was [zero]
#
#
#REVERSE
#
#5: last
#
#4: three
#
#3: Newbie
#
#2: one
#
#1: New One
#
#0: first
#
#
#REVERSE again
#
#5: last
#
#4: three
#
#3: Newbie
#
#2: one
#
#1: New One
#
#0: first
#-----------------------------
    foreach $item (@lines) { }
#-----------------------------
    foreach $i (0 .. $dbobj->length - 1) { }
#-----------------------------
    for ($done_yet = $dbobj->get($k, $v, R_FIRST);
         not $done_yet;
         $done_yet = $dbobj->get($k, $v, R_NEXT) )
    {
        # process key or value
    }
#-----------------------------

