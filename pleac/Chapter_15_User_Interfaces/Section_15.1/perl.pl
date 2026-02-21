
#-----------------------------
use Getopt::Std;

# -v ARG, -D ARG, -o ARG, sets $opt_v, $opt_D, $opt_o
getopt("vDo");              
# -v ARG, -D ARG, -o ARG, sets $args{v}, $args{D}, $args{o}
getopt("vDo", \%args);

getopts("vDo:");         # -v, -D, -o ARG, sets $opt_v, $opt_D, $opt_o
getopts("vDo:", \%args); # -v, -D, -o ARG, sets $args{v}, $args{D}, $args{o}
#-----------------------------
use Getopt::Long;

GetOptions( "verbose"  => \$verbose,     # --verbose
            "Debug"    => \$debug,       # --Debug
            "output=s" => \$output );    # --output=string or --output=string
#-----------------------------
#% rm -r -f /tmp/testdir
#-----------------------------
#% rm -rf /tmp/testdir
#-----------------------------
use Getopt::Std;
getopts("o:");
if ($opt_o) {
    print "Writing output to $opt_o";
}
#-----------------------------
use Getopt::Std;

%option = ();
getopts("Do:", \%option);

if ($option{D}) {
    print "Debugging mode enabled.\n";
}

 # if not set, set output to "-".  opening "-" for writing
 # means STDOUT
 $option{o} = "-" unless defined $option{o};
                             
print "Writing output to file $option{o}\n" unless $option{o} eq "-";
open(STDOUT, "> $option{o}")
     or die "Can't open $option{o} for output: $!\n";
#-----------------------------
#% gnutar --extract --file latest.tar
#-----------------------------
#% gnutar --extract --file=latest.tar
#-----------------------------
use Getopt::Long;

GetOptions( "extract" => \$extract,
            "file=s"  => \$file );

if ($extract) {
    print "I'm extracting.\n";
}

die "I wish I had a file" unless defined $file;
print "Working on the file $file\n";
#-----------------------------

