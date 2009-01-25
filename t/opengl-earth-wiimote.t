#!/usr/bin/perl

use Test::More;

plan tests => 2;

use_ok('OpenGL::Earth::Wiimote');

# Silence warnings
my $have_wiimote =
$OpenGL::Earth::Wiimote::HAVE_WIIMOTE =
$OpenGL::Earth::Wiimote::HAVE_WIIMOTE;

if ($^O =~ m{Win32}) {
    is(
        $have_wiimote => 0,
        'Win32 doesn\'t have a functional Linux::Input::Wiimote library'
    );
}
elsif ($^O =~ m{Linux}i) {
    is(
        $have_wiimote => 1,
        'On Linux we should have a functional Linux::Input::Wiimote library'
    );
}
else {
    is(
        $have_wiimote => 0,
        'On other platforms, Wiimote class is disabled'
    );
}

