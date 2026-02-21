
#-----------------------------
pipe(READER, WRITER);
if (fork) {
    # run parent code, either reading or writing, not both
} else {
    # run child code, either reading or writing, not both
}
#-----------------------------
if ($pid = open(CHILD, "|-")) {
        # run parent code, writing to child
} else {
    die "cannot fork: $!" unless defined $pid;
    # otherwise run child code here, reading from parent
}
#-----------------------------
if ($pid = open(CHILD, "-|")) {
    # run parent code, reading from child
} else {
    die "cannot fork: $!" unless defined $pid;
    # otherwise run child code here, writing to parent
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe1
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe2
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe3
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe4
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe5
#-----------------------------
# ^^INCLUDE^^ include/perl/ch16/pipe6
#-----------------------------
socketpair(READER, WRITER, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
shutdown(READER, 1);        # no more writing for reader
shutdown(WRITER, 0);        # no more reading for writer
#-----------------------------

