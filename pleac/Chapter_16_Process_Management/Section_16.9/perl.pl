
#-----------------------------
@all = `($cmd | sed -e 's/^/stdout: /' ) 2>&1`;
for (@all) { push @{ s/stdout: // ? \@outlines : \@errlines }, $_ }
print "STDOUT:\n", @outlines, "\n";
print "STDERR:\n", @errlines, "\n";
#-----------------------------
open3(*WRITEHANDLE, *READHANDLE, *ERRHANDLE, "program to run");
#-----------------------------
use IPC::Open3;
$pid = open3(*HIS_IN, *HIS_OUT, *HIS_ERR, $cmd);
close(HIS_IN);  # give end of file to kid, or feed him
@outlines = <HIS_OUT>;              # read till EOF
@errlines = <HIS_ERR>;              # XXX: block potential if massive
print "STDOUT:\n", @outlines, "\n";
print "STDERR:\n", @errlines, "\n";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/cmd3sel
#-----------------------------

