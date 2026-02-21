
#-----------------------------
$count = `wc -l < $file`;
die "wc failed: $?" if $?;
chomp($count);
#-----------------------------
open(FILE, "< $file") or die "can't open $file: $!";
$count++ while <FILE>;
# $count now holds the number of lines read
#-----------------------------
$count += tr/\n/\n/ while sysread(FILE, $_, 2 ** 16);
#-----------------------------
open(FILE, "< $file") or die "can't open $file: $!";
$count++ while <FILE>;
# $count now holds the number of lines read
#-----------------------------
open(FILE, "< $file") or die "can't open $file: $!";
for ($count=0; <FILE>; $count++) { }
#-----------------------------
1 while <FILE>;
$count = $.;
#-----------------------------
$/ = '';            # enable paragraph mode for all reads
open(FILE, $file) or die "can't open $file: $!";
1 while <FILE>;
$para_count = $.;
#-----------------------------

