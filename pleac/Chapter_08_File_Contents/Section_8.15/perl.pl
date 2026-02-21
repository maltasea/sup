
#-----------------------------
# $RECORDSIZE is the length of a record, in bytes.
# $TEMPLATE is the unpack template for the record
# FILE is the file to read from
# @FIELDS is an array, one element per field

until ( eof(FILE) ) {
    read(FILE, $record, $RECORDSIZE) == $RECORDSIZE
        or die "short read\n";
    @FIELDS = unpack($TEMPLATE, $record);
}
#-----------------------------
#define UT_LINESIZE           12
#define UT_NAMESIZE           8
#define UT_HOSTSIZE           16

struct utmp {                       /* here are the pack template codes */
    short ut_type;                  /* s for short, must be padded      */
    pid_t ut_pid;                   /* i for integer                    */
    char ut_line[UT_LINESIZE];      /* A12 for 12-char string           */
    char ut_id[2];                  /* A2, but need x2 for alignment    */
    time_t ut_time;                 /* l for long                       */
    char ut_user[UT_NAMESIZE];      /* A8 for 8-char string             */
    char ut_host[UT_HOSTSIZE];      /* A16 for 16-char string           */
    long ut_addr;                   /* l for long                       */
};
#-----------------------------

