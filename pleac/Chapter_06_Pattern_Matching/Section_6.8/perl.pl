
#-----------------------------
while (<>) {
    if (/BEGIN PATTERN/ .. /END PATTERN/) {
        # line falls between BEGIN and END in the
        # text, inclusive.
    }
}

while (<>) {
    if ($FIRST_LINE_NUM .. $LAST_LINE_NUM) {
        # operate only between first and last line, inclusive.
    }
}
#-----------------------------
while (<>) {
    if (/BEGIN PATTERN/ ... /END PATTERN/) {
        # line is between BEGIN and END on different lines
    }
}

while (<>) {
    if ($FIRST_LINE_NUM ... $LAST_LINE_NUM) {
        # operate only between first and last line, but not same
    }
}
#-----------------------------
# command-line to print lines 15 through 17 inclusive (see below)
perl -ne 'print if 15 .. 17' datafile

# print out all <XMP> .. </XMP> displays from HTML doc
while (<>) {
    print if m#<XMP>#i .. m#</XMP>#i;
}
    
# same, but as shell command
# perl -ne 'print if m#<XMP>#i .. m#</XMP>#i' document.html
#-----------------------------
# perl -ne 'BEGIN { $top=3; $bottom=5 }  print if $top .. $bottom' /etc/passwd        # previous command FAILS
# perl -ne 'BEGIN { $top=3; $bottom=5 } \
#     print if $. == $top .. $. ==     $bottom' /etc/passwd    # works
# perl -ne 'print if 3 .. 5' /etc/passwd   # also works
#-----------------------------
print if /begin/ .. /end/;
print if /begin/ ... /end/;
#-----------------------------
while (<>) {
    $in_header =   1  .. /^$/;
    $in_body   = /^$/ .. eof();
}
#-----------------------------
%seen = ();
while (<>) {
    next unless /^From:?\s/i .. /^$/;
    while (/([^<>(),;\s]+\@[^<>(),;\s]+)/g) {
        print "$1\n" unless $seen{$1}++;
    }
}
#-----------------------------

