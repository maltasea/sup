
#-----------------------------
$old_fh = select(OUTPUT_HANDLE);
$| = 1;
select($old_fh);
#-----------------------------
use IO::Handle;
OUTPUT_HANDLE->autoflush(1);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/seeme
#-----------------------------
    select((select(OUTPUT_HANDLE), $| = 1)[0]);
#-----------------------------
use FileHandle;

STDERR->autoflush;          # already unbuffered in stdio
$filehandle->autoflush(0);
#-----------------------------
use IO::Handle;
# assume REMOTE_CONN is an interactive socket handle,
# but DISK_FILE is a handle to a regular file.
autoflush REMOTE_CONN  1;           # unbuffer for clarity
autoflush DISK_FILE    0;           # buffer this for speed
#-----------------------------
# ^^INCLUDE^^ include/perl/ch07/getpcomidx
#-----------------------------

