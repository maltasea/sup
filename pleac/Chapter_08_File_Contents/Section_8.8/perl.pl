
#-----------------------------
# looking for line number $DESIRED_LINE_NUMBER
$. = 0;
do { $LINE = <HANDLE> } until $. == $DESIRED_LINE_NUMBER || eof;
#-----------------------------
@lines = <HANDLE>;
$LINE = $lines[$DESIRED_LINE_NUMBER];
#-----------------------------
# usage: build_index(*DATA_HANDLE, *INDEX_HANDLE)
sub build_index {
    my $data_file  = shift;
    my $index_file = shift;
    my $offset     = 0;

    while (<$data_file>) {
        print $index_file pack("N", $offset);
        $offset = tell($data_file);
    }
}

# usage: line_with_index(*DATA_HANDLE, *INDEX_HANDLE, $LINE_NUMBER)
# returns line or undef if LINE_NUMBER was out of range
sub line_with_index {
    my $data_file   = shift;
    my $index_file  = shift;
    my $line_number = shift;

    my $size;               # size of an index entry
    my $i_offset;           # offset into the index of the entry
    my $entry;              # index entry
    my $d_offset;           # offset into the data file

    $size = length(pack("N", 0));
    $i_offset = $size * ($line_number-1);
    seek($index_file, $i_offset, 0) or return;
    read($index_file, $entry, $size);
    $d_offset = unpack("N", $entry);
    seek($data_file, $d_offset, 0);
    return scalar(<$data_file>);
}

# usage:
open(FILE, "< $file")         or die "Can't open $file for reading: $!\n";
open(INDEX, "+>$file.idx")
        or die "Can't open $file.idx for read/write: $!\n";
build_index(*FILE, *INDEX);
$line = line_with_index(*FILE, *INDEX, $seeking);
#-----------------------------
use DB_File;
use Fcntl;

$tie = tie(@lines, $FILE, "DB_File", O_RDWR, 0666, $DB_RECNO) or die 
    "Cannot open file $FILE: $!\n";
# extract it
$line = $lines[$sought - 1];
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/print_line-v1
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/print_line-v2
#-----------------------------
# ^^INCLUDE^^ include/perl/ch08/print_line-v3
#-----------------------------

