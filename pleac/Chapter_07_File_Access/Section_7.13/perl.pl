
#-----------------------------
$rin = '';
# repeat next line for all filehandles to poll
vec($rin, fileno(FH1), 1) = 1;
vec($rin, fileno(FH2), 1) = 1;
vec($rin, fileno(FH3), 1) = 1;

$nfound = select($rout=$rin, undef, undef, 0);
if ($nfound) {
  # input waiting on one or more of those 3 filehandles
  if (vec($rout,fileno(FH1),1)) { 
      # do something with FH1
  }
  if (vec($rout,fileno(FH2),1)) {
      # do something with FH2
  }
  if (vec($rout,fileno(FH3),1)) {
      # do something with FH3
  }
}
#-----------------------------
use IO::Select;

$select = IO::Select->new();
# repeat next line for all filehandles to poll
$select->add(*FILEHANDLE);
if (@ready = $select->can_read(0)) {
    # input waiting on the filehandles in @ready
}
#-----------------------------
$rin = '';
vec($rin, fileno(FILEHANDLE), 1) = 1;
$nfound = select($rin, undef, undef, 0);    # just check
if ($nfound) {
    $line = <FILEHANDLE>;
    print "I read $line";
}
#-----------------------------

