
#-----------------------------
$revbytes = reverse($string);
#-----------------------------
$revwords = join(" ", reverse split(" ", $string));
#-----------------------------
$gnirts   = reverse($string);       # reverse letters in $string

@sdrow    = reverse(@words);        # reverse elements in @words

$confused = reverse(@words);        # reverse letters in join("", @words)
#-----------------------------
# reverse word order
$string = 'Yoda said, "can you see this?"';
@allwords    = split(" ", $string);
$revwords    = join(" ", reverse @allwords);
print $revwords, "\n";
this?" see you "can said, Yoda
#-----------------------------
$revwords = join(" ", reverse split(" ", $string));
#-----------------------------
$revwords = join("", reverse split(/(\s+)/, $string));
#-----------------------------
$word = "reviver";
$is_palindrome = ($word eq reverse($word));
#-----------------------------
#% perl -nle 'print if $_ eq reverse && length > 5' /usr/dict/words
#deedeed
#
#degged
#
#deified
#
#denned
#
#hallah
#
#kakkak
#
#murdrum
#
#redder
#
#repaper
#
#retter
#
#reviver
#
#rotator
#
#sooloos
#
#tebbet
#
#terret
#
#tut-tut
#-----------------------------

