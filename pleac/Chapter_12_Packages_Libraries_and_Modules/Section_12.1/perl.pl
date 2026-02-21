
#-----------------------------
package YourModule;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 1.00;              # Or higher
@ISA = qw(Exporter);

@EXPORT      = qw(...);       # Symbols to autoexport (:DEFAULT tag)
@EXPORT_OK   = qw(...);       # Symbols to export on request
%EXPORT_TAGS = (              # Define names for sets of symbols
    TAG1 => [...],
    TAG2 => [...],
    ...
);

########################
# your code goes here
########################

1;                            # this should be your last line
#-----------------------------
use YourModule;               # Import default symbols into my package.
use YourModule qw(...);       # Import listed symbols into my package.
use YourModule ();            # Do not import any symbols
use YourModule qw(:TAG1);     # Import whole tag set
#-----------------------------
    @EXPORT = qw(&F1 &F2 @List);
    @EXPORT = qw( F1  F2 @List);        # same thing
#-----------------------------
    @EXPORT_OK = qw(Op_Func %Table);
#-----------------------------
    use YourModule qw(Op_Func %Table F1);
#-----------------------------
    use YourModule qw(:DEFAULT %Table);
#-----------------------------
    %EXPORT_TAGS = (
        Functions => [ qw(F1 F2 Op_Func) ],
        Variables => [ qw(@List %Table)  ],
);
#-----------------------------
    use YourModule qw(:Functions %Table);
#-----------------------------
    @{
 
$YourModule::EXPORT_TAGS{Functions}
 
}
, 
#-----------------------------

