
#-----------------------------
$answer = $var1 . func() . $var2;   # scalar only
#-----------------------------
$answer = "STRING @{[ LIST EXPR ]} MORE STRING";
$answer = "STRING ${\( SCALAR EXPR )} MORE STRING";
#-----------------------------
$phrase = "I have " . ($n + 1) . " guanacos.";
$phrase = "I have ${\($n + 1)} guanacos.";
#-----------------------------
print "I have ",  $n + 1, " guanacos.\n";
#-----------------------------
some_func("What you want is @{[ split /:/, $rec ]} items");
#-----------------------------
die "Couldn't send mail" unless send_mail(<<"EOTEXT", $target);
To: $naughty
From: Your Bank
Cc: @{ get_manager_list($naughty) }
Date: @{[ do { my $now = `date`; chomp $now; $now } ]} (today)

Dear $naughty,

Today, you bounced check number @{[ 500 + int rand(100) ]} to us.
Your account is now closed.

Sincerely,
the management
EOTEXT
#-----------------------------

