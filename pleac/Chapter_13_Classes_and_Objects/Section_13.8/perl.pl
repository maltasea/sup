
#-----------------------------
$obj->isa("HTTP::Message");                  # as object method
HTTP::Response->isa("HTTP::Message");       # as class method

if ($obj->can("method_name")) { .... }       # check method validity
#-----------------------------
$has_io = $fd->isa("IO::Handle");
$itza_handle = IO::Socket->isa("IO::Handle");
#-----------------------------
$his_print_method = $obj->can('as_string');
#-----------------------------
Some_Module->VERSION(3.0);
$his_vers = $obj->
VERSION()
;
#-----------------------------
use Some_Module 3.0;
#-----------------------------
use vars qw($VERSION);
$VERSION = '1.01';
#-----------------------------

