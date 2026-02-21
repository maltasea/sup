
#-----------------------------
use IPC::Open2;

open2(*README, *WRITEME, $program);
print WRITEME "here's your input\n";
$output = <README>;
close(WRITEME);
close(README);
#-----------------------------
open(DOUBLE_HANDLE, "| program args |")     # WRONG
#-----------------------------
use IPC::Open2;
use IO::Handle;

($reader, $writer) = (IO::Handle->new, IO::Handle->new);
open2($reader, $writer, $program);
#-----------------------------
eval {
    open2($readme, $writeme, @program_and_arguments);
};
if ($@) { 
    if ($@ =~ /^open2/) {
        warn "open2 failed: $!\n$@\n";
        return;
    }
    die;            # reraise unforeseen exception
}
#-----------------------------

