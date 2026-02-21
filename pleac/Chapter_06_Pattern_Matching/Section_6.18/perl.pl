
#-----------------------------
my $eucjp = q{                 # EUC-JP encoding subcomponents:
    [\x00-\x7F]                # ASCII/JIS-Roman (one-byte/character)
  | \x8E[\xA0-\xDF]            # half-width katakana (two bytes/char)
  | \x8F[\xA1-\xFE][\xA1-\xFE] # JIS X 0212-1990 (three bytes/char)
  | [\xA1-\xFE][\xA1-\xFE]     # JIS X 0208:1997 (two bytes/char)
};
#-----------------------------
/^ (?: $eucjp )*?  \xC5\xEC\xB5\xFE/ox # Trying to find Tokyo
#-----------------------------
/^ (  (?:eucjp)*? ) $Tokyo/$1$Osaka/ox
#-----------------------------
/\G (  (?:eucjp)*? ) $Tokyo/$1$Osaka/gox
#-----------------------------
@chars = /$eucjp/gox; # One character per list element
#-----------------------------
while (<>) {
  my @chars = /$eucjp/gox; # One character per list element
  for my $char (@chars) {
    if (length($char) == 1) {
      # Do something interesting with this one-byte character
    } else {
      # Do something interesting with this multiple-byte character
    }
  }
  my $line = join("",@chars); # Glue list back together
  print $line;
}
#-----------------------------
$is_eucjp = m/^(?:$eucjp)*$/xo;
#-----------------------------
$is_eucjp = m/^(?:$eucjp)*$/xo;
$is_sjis  = m/^(?:$sjis)*$/xo;
#-----------------------------
while (<>) {
  my @chars = /$eucjp/gox; # One character per list element
  for my $euc (@chars) {
    my $uni = $euc2uni{$char};
    if (defined $uni) {
        $euc = $uni;
    } else {
        ## deal with unknown EUC->Unicode mapping here.
    }
  }
  my $line = join("",@chars);
  print $line;
}
#-----------------------------

