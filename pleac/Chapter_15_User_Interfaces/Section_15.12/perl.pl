
#-----------------------------
#% rep ps aux
#% rep netstat
#% rep -2.5 lpq
#-----------------------------
# ^^INCLUDE^^ include/perl/ch15/rep
#-----------------------------
keypad(1);                  # enable keypad mode
$key = getch();
if ($key eq 'k'     ||      # vi mode
    $key eq "\cP"   ||      # emacs mode
    $key eq KEY_UP)         # arrow mode
{
    # do something
} 
#-----------------------------
#		       Template Entry Demonstration 
#
#   Address Data Example                                     Record # ___
#
#   Name: [________________________________________________]
#   Addr: [________________________________________________]
#   City: [__________________]          State: [__]       Zip: [\\\\\] 
#
#   Phone: (\\\) \\\-\\\\                            Password: [^^^^^^^^]
#
#   Enter all information available.
#   Edit fields with left/right arrow keys or "delete".
#   Switch fields with "Tab" or up/down arrow keys.
#   Indicate completion by pressing "Return".
#   Refresh screen with "Control-L".
#   Abort this demo here with "Control-X".
#-----------------------------

