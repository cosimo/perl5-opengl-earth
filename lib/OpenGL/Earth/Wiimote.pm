#
# Nintendo Wiimote controller class
#
# $Id$

package OpenGL::Earth::Wiimote;

use strict;
use Carp;
use Linux::Input::Wiimote;

sub disconnect {
	my ($wii) = @_;
	$wii->disconnect();
}

sub get_keys {
	my ($wii) = @_;
	my $k = {};

    if ( $wii->get_wiimote_keys_home ) {
        $k->{home} = 1;
    }
    if ( $wii->get_wiimote_keys_up ) {
        $k->{up} = 1;
    }
    if ( $wii->get_wiimote_keys_down ) {
        $k->{down} = 1;
    }
    if ( $wii->get_wiimote_keys_left ) {
        $k->{left} = 1;
    }
    if ( $wii->get_wiimote_keys_right ) {
        $k->{right} = 1;
    }
    if ( $wii->get_wiimote_keys_a ) {
        $k->{'A'} = 1;
    }
    if ( $wii->get_wiimote_keys_b ) {
        $k->{'B'} = 1;
    }
    if ( $wii->get_wiimote_keys_1 ) {
        $k->{'1'} = 1;
    }
    if ( $wii->get_wiimote_keys_2 ) {
        $k->{'2'} = 1;
    }
    if ( $wii->get_wiimote_keys_minus ) {
        $k->{'-'} = 1;
    }
    if ( $wii->get_wiimote_keys_plus ) {
        $k->{'+'} = 1;
    }

	return $k;
}

sub get_motion ($) {

	my ($wii) = @_;
	my $mt = {};

	$wii->wiimote_update();

	$mt->{axis_x} = $wii->get_wiimote_axis_x();
    $mt->{axis_y} = $wii->get_wiimote_axis_y();
    $mt->{axis_z} = $wii->get_wiimote_axis_z();

	$mt->{tilt_x} = $wii->get_wiimote_tilt_x();
    $mt->{tilt_y} = $wii->get_wiimote_tilt_y();
    $mt->{tilt_z} = $wii->get_wiimote_tilt_z();

	$mt->{force_x} = $wii->get_wiimote_force_x();
    $mt->{force_y} = $wii->get_wiimote_force_y();
    $mt->{force_z} = $wii->get_wiimote_force_z();

	return $mt;
}

sub init {
	my $wii = Linux::Input::Wiimote->new();
	my $addr = '00:1F:C5:06:5E:BB';

	my $connect = $wii->wiimote_connect($addr);
	if ($connect == -1 ) {
		carp "Can't connect to Wiimote at $addr\n";
	}

	# Init wiimote to receive appropriate sensors data
	$wii->wiimote_update();
	$wii->set_wiimote_rumble(0);
	$wii->set_wiimote_ir(1);
	$wii->activate_wiimote_accelerometer();

	return $wii;
}

1;

