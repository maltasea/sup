
#-----------------------------
$variable = *FILEHANDLE;        # save in variable
subroutine(*FILEHANDLE);        # or pass directly

sub subroutine {
    my $fh = shift;
    print $fh "Hello, filehandle!\n";
}
#-----------------------------
use FileHandle;                   # make anon filehandle
$fh = FileHandle->new();

use IO::File;                     # 5.004 or higher
$fh = IO::File->new();
#-----------------------------
$fh_a = IO::File->new("< /etc/motd")    or die "open /etc/motd: $!";
$fh_b = *STDIN;
some_sub($fh_a, $fh_b);
#-----------------------------
sub return_fh {             # make anon filehandle
    local *FH;              # must be local, not my
    # now open it if you want to, then...
    return *FH;
}

$handle = return_fh();
#-----------------------------
sub accept_fh {
    my $fh = shift;
    print $fh "Sending to indirect filehandle\n";
}
#-----------------------------
sub accept_fh {
    local *FH = shift;
    print  FH "Sending to localized filehandle\n";
}
#-----------------------------
accept_fh(*STDOUT);
accept_fh($handle);
#-----------------------------
@fd = (*STDIN, *STDOUT, *STDERR);
print $fd[1] "Type it: ";                           # WRONG
$got = <$fd[0]>                                     # WRONG
print $fd[2] "What was that: $got";                 # WRONG
#-----------------------------
print  { $fd[1] } "funny stuff\n";
printf { $fd[1] } "Pity the poor %x.\n", 3_735_928_559;
Pity the poor deadbeef.
#-----------------------------
$ok = -x "/bin/cat";                
print { $ok ? $fd[1] : $fd[2] } "cat stat $ok\n";
print { $fd[ 1 + ($ok || 0) ]  } "cat stat $ok\n";           
#-----------------------------
$got = readline($fd[0]);
#-----------------------------

