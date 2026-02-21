
#-----------------------------
print $$sref;    # prints the scalar value that the reference $sref refers to
$$sref = 3;      # assigns to $sref's referent
#-----------------------------
print ${$sref};             # prints the scalar $sref refers to
${$sref} = 3;               # assigns to $sref's referent
#-----------------------------
$aref = \@array;
#-----------------------------
$pi = \3.14159;
$$pi = 4;           # runtime error
#-----------------------------
$aref = [ 3, 4, 5 ];                                # new anonymous array
$href = { "How" => "Now", "Brown" => "Cow" };       # new anonymous hash
#-----------------------------
undef $aref;
@$aref = (1, 2, 3);
print $aref;
ARRAY(0x80c04f0)
#-----------------------------
$a[4][23][53][21] = "fred";
print $a[4][23][53][21];
fred

print $a[4][23][53];
ARRAY(0x81e2494)

print $a[4][23];
ARRAY(0x81e0748)

print $a[4];
ARRAY(0x822cd40)
#-----------------------------
$op_cit = cite($ibid)       or die "couldn't make a reference";
#-----------------------------
$Nat = { "Name"     => "Leonhard Euler",
         "Address"  => "1729 Ramanujan Lane\nMathworld, PI 31416",
         "Birthday" => 0x5bb5580,
       };
#-----------------------------

