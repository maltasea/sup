
#-----------------------------
$preference_value = cookie("preference name");
#-----------------------------
$packed_cookie = cookie( -NAME    => "preference name",
                         -VALUE   => "whatever you'd like",
                         -EXPIRES => "+2y");
#-----------------------------
print header(-COOKIE => $packed_cookie);
#-----------------------------
# ^^INCLUDE^^ include/perl/ch19/ic_cookies
#-----------------------------

