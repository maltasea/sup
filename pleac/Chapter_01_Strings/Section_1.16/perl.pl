
#-----------------------------
 use Text::Soundex;

 $CODE  = soundex($STRING);
 @CODES = soundex(@LIST);
#-----------------------------
use Text::Soundex;
use User::pwent;

print "Lookup user: ";
chomp($user = <STDIN>);
exit unless defined $user;
$name_code = soundex($user);

while ($uent = getpwent()) {
    ($firstname, $lastname) = $uent->gecos =~ /(\w+)[^,]*\b(\w+)/;

    if ($name_code eq soundex($uent->name) ||
        $name_code eq soundex($lastname)   ||
        $name_code eq soundex($firstname)  )
    {
        printf "%s: %s %s\n", $uent->name, $firstname, $lastname;
    }
}
#-----------------------------

