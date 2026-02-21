
#-----------------------------
# backslash
$var =~ s/([CHARLIST])/\\$1/g;

# double
$var =~ s/([CHARLIST])/$1$1/g;
#-----------------------------
$string =~ s/%/%%/g;
#-----------------------------
$string = q(Mom said, "Don't do that."); #'
$string =~ s/(['"])/\\$1/g;
#-----------------------------
$string = q(Mom said, "Don't do that.");
$string =~ s/(['"])/$1$1/g;
#-----------------------------
$string =~ s/([^A-Z])/\\$1/g;
#-----------------------------
$string = "this \Qis a test!\E";
$string = "this is\\ a\\ test\\!";
$string = "this " . quotemeta("is a test!");
#-----------------------------

