
#-----------------------------
use Expect;

$command = Expect->spawn("program to run")
    or die "Couldn't start program: $!\n";

# prevent the program's output from being shown on our STDOUT
$command->log_stdout(0);

# wait 10 seconds for "Password:" to appear
unless ($command->expect(10, "Password")) {
    # timed out
}

# wait 20 seconds for something that matches /[lL]ogin: ?/
unless ($command->expect(20, -re => '[lL]ogin: ?')) {
    # timed out
}

# wait forever for "invalid" to appear
unless ($command->expect(undef, "invalid")) {
    # error occurred; the program probably went away
}

# send "Hello, world" and a carriage return to the program
print $command "Hello, world\r";

# if the program will terminate by itself, finish up with
$command->soft_close();
    
# if the program must be explicitly killed, finish up with
$command->hard_close();
#-----------------------------
$which = $command->expect(30, "invalid", "succes", "error", "boom");
if ($which) {
    # found one of those strings
}
#-----------------------------

