
#-----------------------------
#% ggh http://www.perl.com/index.html
#-----------------------------
#% ggh perl
#-----------------------------
#% ggh mailto:
#-----------------------------
#% ggh -regexp '(?i)\bfaq\b'
#-----------------------------
#% ggh -epoch http://www.perl.com/perl/
#-----------------------------
#% ggh -gmtime http://www.perl.com/perl/
#-----------------------------
#% ggh | less
#-----------------------------
#% ggh -epoch | sort -rn | less
#-----------------------------
#% ggh -epoch | sort -rn | perl -pe 's/\d+/localtime $&/e' | less
#-----------------------------
# ^^INCLUDE^^ include/perl/ch14/ggh
#-----------------------------

