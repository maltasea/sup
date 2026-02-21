
#-----------------------------
while ($line = <>) {
    if ($line =~ /$pattern/o) {
        # do something
    }
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/popgrep1
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/popgrep2
#-----------------------------
while (defined($line = <>)) {
     if ($line =~ /\bCO\b/) { print $line; next; }
     if ($line =~ /\bON\b/) { print $line; next; }
     if ($line =~ /\bMI\b/) { print $line; next; }
     if ($line =~ /\bWI\b/) { print $line; next; }
     if ($line =~ /\bMN\b/) { print $line; next; }
}
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/popgrep3
#-----------------------------
sub {
      m/\b$popstates[0]\b/o || m/\b$popstates[1]\b/o ||
      m/\b$popstates[2]\b/o || m/\b$popstates[3]\b/o ||
      m/\b$popstates[4]\b/o
  }
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/grepauth
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/popgrep4
#-----------------------------

