
#-----------------------------
$size = pack("L", 0);
ioctl(FH, $FIONREAD, $size)     or die "Couldn't call ioctl: $!\n";
$size = unpack("L", $size);

# $size bytes can be read
#-----------------------------
require 'sys/ioctl.ph';

$size = pack("L", 0);
ioctl(FH, FIONREAD(), $size)    or die "Couldn't call ioctl: $!\n";
$size = unpack("L", $size);
#-----------------------------
#% grep FIONREAD /usr/include/*/*
#/usr/include/asm/ioctls.h:#define FIONREAD      0x541B
#-----------------------------
#% cat > fionread.c
##include <sys/ioctl.h>
#main() {
#
#    printf("%#08x\n", FIONREAD);
#}
#^D
#% cc -o fionread fionread
#% ./fionread
#0x4004667f
#-----------------------------
$FIONREAD = 0x4004667f;         # XXX: opsys dependent

$size = pack("L", 0);
ioctl(FH, $FIONREAD, $size)     or die "Couldn't call ioctl: $!\n";
$size = unpack("L", $size);
#-----------------------------

