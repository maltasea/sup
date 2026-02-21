
#-----------------------------
@ordered = sort { compare() } @unordered;
#-----------------------------
@precomputed = map { [compute(),$_] } @unordered;
@ordered_precomputed = sort { $a->[0] <=> $b->[0] } @precomputed;
@ordered = map { $_->[1] } @ordered_precomputed;
#-----------------------------
@ordered = map { $_->[1] }
           sort { $a->[0] <=> $b->[0] }
           map { [compute(), $_] }
           @unordered;
#-----------------------------
@ordered = sort { $a->name cmp $b->name } @employees;
#-----------------------------
foreach $employee (sort { $a->name cmp $b->name } @employees) {
    print $employee->name, " earns \$", $employee->salary, "\n";
}
#-----------------------------
@sorted_employees = sort { $a->name cmp $b->name } @employees;
foreach $employee (@sorted_employees) {
    print $employee->name, " earns \$", $employee->salary, "\n";
}
# load %bonus
foreach $employee (@sorted_employees) {
    if ( $bonus{ $employee->ssn } ) {
      print $employee->name, " got a bonus!\n";
    }
}
#-----------------------------
@sorted = sort { $a->name cmp $b->name
                           ||
                  $b->age <=> $a->age } @employees;
#-----------------------------
use User::pwent qw(getpwent);
@users = ();
# fetch all users
while (defined($user = getpwent)) {
    push(@users, $user);
}
    @users = sort { $a->name cmp $b->name } @users;
foreach $user (@users) {
    print $user->name, "\n";
}
#-----------------------------
@sorted = sort { substr($a,1,1) cmp substr($b,1,1) } @names;
#-----------------------------
@sorted = sort { length $a <=> length $b } @strings;
#-----------------------------
@temp   = map  { [ length $_, $_ ] } @strings;
@temp   = sort { $a->[0] <=> $b->[0] } @temp;
@sorted = map  { $_->[1] } @temp;
#-----------------------------
@sorted = map  { $_->[1] }
          sort { $a->[0] <=> $b->[0] }
          map  { [ length $_, $_ ] }
          @strings;
#-----------------------------
@temp          = map  { [ /(\d+)/, $_ ] } @fields;
@sorted_temp   = sort { $a->[0] <=> $b->[0] } @temp;
@sorted_fields = map  { $_->[1] } @sorted_temp;
#-----------------------------
@sorted_fields = map  { $_->[1] }
                 sort { $a->[0] <=> $b->[0] }
                 map  { [ /(\d+)/, $_ ] }
                 @fields;
#-----------------------------
print map  { $_->[0] }             # whole line
      sort {
              $a->[1] <=> $b->[1]  # gid
                      ||
              $a->[2] <=> $b->[2]  # uid
                      ||
              $a->[3] cmp $b->[3]  # login
      }
      map  { [ $_, (split /:/)[3,2,0] ] }
      `cat /etc/passwd`;
#-----------------------------

