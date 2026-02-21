
#-----------------------------
use Term::ReadKey;

ReadMode ('cbreak');

if (defined ($char = ReadKey(-1)) ) {
    # input was waiting and it was $char
} else {
    # no input was waiting
}

ReadMode ('normal');                  # restore normal tty settings
#-----------------------------

