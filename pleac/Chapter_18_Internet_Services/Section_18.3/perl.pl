
#-----------------------------
use Mail::Mailer;

$mailer = Mail::Mailer->new("sendmail");
$mailer->open({ From    => $from_address,
                To      => $to_address,
                Subject => $subject,
              })
    or die "Can't open: $!\n";
print $mailer $body;
$mailer->
close();
#-----------------------------
open(SENDMAIL, "|/usr/lib/sendmail -oi -t -odq")
                    or die "Can't fork for sendmail: $!\n";
print SENDMAIL <<"EOF";
From: User Originating Mail <me\@host>
To: Final Destination <you\@otherhost>
Subject: A relevant subject line

Body of the message goes here, in as many lines as you like.
EOF
close(SENDMAIL)     or warn "sendmail didn't close nicely";
#-----------------------------
$mailer = Mail::Mailer->new("sendmail");
#-----------------------------
$mailer = Mail::Mailer->new("mail", "/u/gnat/bin/funkymailer");
#-----------------------------
$mailer = Mail::Mailer->new("smtp", "mail.myisp.com");
#-----------------------------
eval {
    $mailer = Mail::Mailer->new("bogus", "arguments");
    # ...
};
if ($@) {
    # the eval failed
    print "Couldn't send mail: $@\n";
} else {
    # the eval succeeded
    print "The authorities have been notified.\n";
}
#-----------------------------
$mailer->open( 'From'    => 'Nathan Torkington <gnat@frii.com>',
               'To'      => 'Tom Christiansen <tchrist@perl.com>',
               'Subject' => 'The Perl Cookbook' );
#-----------------------------
print $mailer <<EO_SIG;
Are we ever going to finish this book?
My wife is threatening to leave me.
She says I love EMACS more than I love her.
Do you have a recipe that can help me?

Nat
EO_SIG
#-----------------------------
close($mailer)                      or die "can't close mailer: $!";
#-----------------------------
open(SENDMAIL, "|/usr/sbin/sendmail -oi -t -odq")
            or die "Can't fork for sendmail: $!\n";
print SENDMAIL <<"EOF";
From: Tom Christiansen <tchrist\@perl.com>
To: Nathan Torkington <gnat\@frii.com>
Subject: Re: The Perl Cookbook

(1) We will never finish the book.
(2) No man who uses EMACS is deserving of love.
(3) I recommend coq au vi.

tom
EOF
close(SENDMAIL);
#-----------------------------

