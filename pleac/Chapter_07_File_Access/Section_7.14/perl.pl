
#-----------------------------
use Fcntl;

sysopen(MODEM, "/dev/cua0", O_NONBLOCK|O_RDWR)
    or die "Can't open modem: $!\n";
#-----------------------------
use Fcntl;

$flags = '';
fcntl(HANDLE, F_GETFL, $flags)
    or die "Couldn't get flags for HANDLE : $!\n";
$flags |= O_NONBLOCK;
fcntl(HANDLE, F_SETFL, $flags)
    or die "Couldn't set flags for HANDLE: $!\n";
#-----------------------------
use POSIX qw(:errno_h);

$rv = syswrite(HANDLE, $buffer, length $buffer);
if (!defined($rv) && $! == EAGAIN) {
    # would block
} elsif ($rv != length $buffer) {
    # incomplete write
} else {
    # successfully wrote
}

$rv = sysread(HANDLE, $buffer, $BUFSIZ);
if (!defined($rv) && $! == EAGAIN) {
    # would block
} else {
    # successfully read $rv bytes from HANDLE
}
#-----------------------------

