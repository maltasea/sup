
#-----------------------------
$age = 18;          # global variable
if (CONDITION) {
    local $age = 23;
    func();         # sees temporary value of 23
} # restore old value at block exit
#-----------------------------
$para = get_paragraph(*FH);        # pass filehandle glob 
$para = get_paragraph(\*FH);       # pass filehandle by glob reference
$para = get_paragraph(*IO{FH});    # pass filehandle by IO reference
sub get_paragraph {
    my $fh = shift;  
    local $/ = '';        
    my $paragraph = <$fh>;
    chomp($paragraph);
    return $paragraph;
} 
#-----------------------------
$contents = get_motd();
sub get_motd {
    local *MOTD;
    open(MOTD, "/etc/motd")        or die "can't open motd: $!";
    local $/ = undef;  # slurp full file;
    local $_ = <MOTD>;
    close (MOTD);
    return $_;
} 
#-----------------------------
return *MOTD;
#-----------------------------
my @nums = (0 .. 5);
sub first { 
    local $nums[3] = 3.14159;
    second();
}
sub second {
    print "@nums\n";
} 
second();
0 1 2 3 4 5

first();
0 1 2 3.14159 4 5
#-----------------------------
sub first {
    local $SIG{INT} = 'IGNORE';
    second();
} 
#-----------------------------
sub func {
    local($x, $y) = @_;
    #....
} 
#-----------------------------
sub func {
    my($x, $y) = @_;
    #....
} 
#-----------------------------
&func(*Global_Array);
sub func {
    local(*aliased_array) = shift;
    for (@aliased_array) { .... }
} 
#-----------------------------
func(\@Global_Array);
sub func {
    my $array_ref  = shift;
    for (@$array_ref) { .... }
} 
#-----------------------------

