
#-----------------------------
use Tk;

$main = MainWindow->new();

# Create a horizontal space at the top of the window for the
# menu to live in.
$menubar = $main->Frame(-relief              => "raised",
                        -borderwidth         => 2)
                ->pack (-anchor              => "nw",
                        -fill                => "x");

# Create a button labeled "File" that brings up a menu
$file_menu = $menubar->Menubutton(-text      => "File",
                                  -underline => 1)
                     ->pack      (-side      => "left" );
# Create entries in the "File" menu
$file_menu->command(-label   => "Print",
                    -command => \&Print);
#-----------------------------
$file_menu = $menubar->Menubutton(-text     => "File",
                                 -underline => 1,
                                 -menuitems => [
              [ Button => "Print",-command  => \&Print ],
               [ Button => "Save",-command  => \&Save  ] ])
                           ->pack(-side     => "left");
#-----------------------------
    $file_menu->command(-label   => "Quit Immediately",
                        -command => sub { exit } );
#-----------------------------
$file_menu->separator();
#-----------------------------
$options_menu->checkbutton(-label    => "Create Debugging File",
                           -variable => \$debug,
                           -onvalue  => 1,
                           -offvalue => 0);
#-----------------------------
$debug_menu->radiobutton(-label    => "Level 1",
                         -variable => \$log_level,
                         -value    => 1);

$debug_menu->radiobutton(-label    => "Level 2",
                         -variable => \$log_level,
                         -value    => 2);

$debug_menu->radiobutton(-label    => "Level 3",
                         -variable => \$log_level,
                         -value    => 3);
#-----------------------------
# step 1: create the cascading menu entry
$format_menu->cascade          (-label    => "Font");

# step 2: get the new Menu we just made
$font_menu = $format_menu->cget("-menu");

# step 3: populate that Menu
$font_menu->radiobutton        (-label    => "Courier",
                                -variable => \$font_name,
                                -value    => "courier");
$font_menu->radiobutton        (-label    => "Times Roman",
                                -variable => \$font_name,
                                -value    => "times");
#-----------------------------
$format_menu = $menubar->Menubutton(-text      => "Format",
                                    -underline => 1
                                    -tearoff   => 0)
                       ->pack;

$font_menu  = $format_menu->cascade(-label     => "Font",
                                    -tearoff   => 0);
#-----------------------------
my $f = $menubar->Menubutton(-text => "Edit", -underline => 0,
                              -menuitems =>
    [
     [Button => 'Copy',        -command => \&edit_copy ],
     [Button => 'Cut',         -command => \&edit_cut ],
     [Button => 'Paste',       -command => \&edit_paste  ],
     [Button => 'Delete',      -command => \&edit_delete ],
     [Separator => ''],
     [Cascade => 'Object ...', -tearoff => 0,
                               -menuitems => [
        [ Button => "Circle",  -command => \&edit_circle ],
        [ Button => "Square",  -command => \&edit_square ],
        [ Button => "Point",   -command => \&edit_point ] ] ],
    ])->grid(-row => 0, -column => 0, -sticky => 'w');
#-----------------------------

