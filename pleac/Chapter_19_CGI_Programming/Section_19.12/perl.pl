
#-----------------------------
use CGI qw(:standard);
print hidden("bacon");
#-----------------------------
    print submit(-NAME => ".State", -VALUE => "Checkout");
#-----------------------------
sub to_page { return submit( -NAME => ".State", -VALUE => shift ) }
#-----------------------------
$page = param(".State") || "Default";
#-----------------------------
if ($page eq "Default") {
    front_page();
} elsif ($page eq "Checkout") {
    checkout();
} else {
    no_such_page();         # when we get a .State that doesn't exist
}
#-----------------------------
%States = (
    'Default'     => \&front_page,
    'Shirt'       => \&shirt,
    'Sweater'     => \&sweater,
    'Checkout'    => \&checkout,
    'Card'        => \&credit_card,
    'Order'       => \&order,
    'Cancel'      => \&front_page,
);

if ($States{$page}) {
    $States{$page}->();   # call the correct subroutine 
} else {
    no_such_page();
}
#-----------------------------
while (($state, $sub) = each %States) {
    $sub->( $page eq $state );
}
#-----------------------------
sub t_shirt {
    my $active = shift;

    unless ($active) {
        print hidden("size"), hidden("color");
        return;
    }

    print p("You want to buy a t-shirt?");
    print p("Size: ", popup_menu('size', [ qw(XL L M S XS) ]));
    print p("Color:", popup_menu('color', [ qw(Black White) ]));

    print p( to_page("Shoes"), to_page("Checkout") );
}
#-----------------------------
print header("Program Title"), start_html();
print standard_header(), begin_form();
while (($state, $sub) = each %States) {
    $sub->( $page eq $state );
}
print standard_footer(), end_form(), end_html();
#-----------------------------

