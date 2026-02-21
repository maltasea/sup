
#-----------------------------
while (defined($line = <FH>) ) {
    chomp $line;
    if ($line =~ s/\\$//) {
        $line .= <FH>;
        redo unless eof(FH);
    }
    # process full record in $line here
}
#-----------------------------
# DISTFILES = $(DIST_COMMON) $(SOURCES) $(HEADERS) \
#         $(TEXINFOS) $(INFOS) $(MANS) $(DATA)
# DEP_DISTFILES = $(DIST_COMMON) $(SOURCES) $(HEADERS) \
#         $(TEXINFOS) $(INFO_DEPS) $(MANS) $(DATA) \
#         $(EXTRA_DIST)
#-----------------------------
if ($line =~ s/\\\s*$//) { 
    # as before
}
#-----------------------------

