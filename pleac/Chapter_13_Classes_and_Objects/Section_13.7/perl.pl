
#-----------------------------
$methname = "flicker";
$obj->$methname(10);         # calls $obj->flicker(10);

# call three methods on the object, by name
foreach $m ( qw(start run stop) ) {
    $obj->
$m();

} 
#-----------------------------
@methods = qw(name rank serno);
%his_info = map { $_ => $ob->$_() } @methods;

# same as this:

%his_info = (
    'name'  => $ob->
name()
,
    'rank'  => $ob->
rank()
,
    'serno' => $ob->
serno()
,
);
#-----------------------------
my $fnref = sub { $ob->method(@_) };
#-----------------------------
$fnref->(10, "fred");
#-----------------------------
$obj->method(10, "fred");
#-----------------------------
$obj->can('method_name')->($obj_target, @arguments)
   if $obj_target->isa( ref $obj );
#-----------------------------

