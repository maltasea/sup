
#-----------------------------
# assumes the &shuffle sub from Chapter 4
while (<INPUT>) {
    push(@lines, $_);
}
@reordered = shuffle(@lines);
foreach (@reordered) {
    print OUTPUT $_;
}
#-----------------------------

