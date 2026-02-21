
#-----------------------------
use File::Find;
sub process_file {
    # do whatever;
}
find(\&process_file, @DIRLIST);
#-----------------------------
@ARGV = qw(.) unless @ARGV;
use File::Find;
find sub { print $File::Find::name, -d && '/', "\n" }, @ARGV;
#-----------------------------
use File::Find;
@ARGV = ('.') unless @ARGV;
my $sum = 0;
find sub { $sum += -s }, @ARGV;
print "@ARGV contains $sum bytes\n";
#-----------------------------
use File::Find;
@ARGV = ('.') unless @ARGV;
my ($saved_size, $saved_name) = (-1, '');
sub biggest {
    return unless -f && -s _ > $saved_size;
    $saved_size = -s _;
    $saved_name = $File::Find::name;
}
find(\&biggest, @ARGV);
print "Biggest file $saved_name in @ARGV is $saved_size bytes long.\n";
#-----------------------------
use File::Find;
@ARGV = ('.') unless @ARGV;
my ($age, $name);
sub youngest {
    return if defined $age && $age > (stat($_))[9];
    $age = (stat(_))[9];
    $name = $File::Find::name;
}
find(\&youngest, @ARGV);
print "$name " . scalar(localtime($age)) . "\n";
#-----------------------------
# ^^INCLUDE^^ include/perl/ch09/fdirs
#-----------------------------
find sub { print $File::Find::name if -d }, @ARGV;
#-----------------------------
find { print $name if -d } @ARGV;
#-----------------------------

