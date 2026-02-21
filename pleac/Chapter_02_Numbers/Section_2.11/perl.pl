
#-----------------------------
BEGIN {
    use constant PI => 3.14159265358979;

    sub deg2rad {
        my $degrees = shift;
        return ($degrees / 180) * PI;
    }

    sub rad2deg {
        my $radians = shift;
        return ($radians / PI) * 180;
    }
}
#-----------------------------
use Math::Trig;

$radians = deg2rad($degrees);
$degrees = rad2deg($radians);
#-----------------------------
# deg2rad and rad2deg defined either as above or from Math::Trig
sub degree_sine {
    my $degrees = shift;
    my $radians = deg2rad($degrees);
    my $result = sin($radians);

    return $result;
}
#-----------------------------

