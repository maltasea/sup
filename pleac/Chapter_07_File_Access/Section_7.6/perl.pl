
#-----------------------------
while (<DATA>) {
    # process the line
}
#__DATA__
# your data goes here
#-----------------------------
while (<main::DATA>) {
    # process the line
}
#__END__
# your data goes here
#-----------------------------
use POSIX qw(strftime);

$raw_time = (stat(DATA))[9];
$size     = -s DATA;
$kilosize = int($size / 1024) . 'k';

print "<P>Script size is $kilosize\n";
print strftime("<P>Last script update: %c (%Z)\n", localtime($raw_time));

#__DATA__
#DO NOT REMOVE THE PRECEDING LINE.
#Everything else in this file will be ignored.
#-----------------------------

