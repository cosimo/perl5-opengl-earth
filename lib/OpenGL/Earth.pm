# $Id$

package OpenGL::Earth;

$VERSION = '0.01';

use strict;
use warnings;
use OpenGL;

# Some global variables

# Window and texture IDs, window width and height.
our $WINDOW_ID;

our $WINDOW_WIDTH = 600;
our $WINDOW_HEIGHT = 600;
our @TEXTURES;
our $WII;

# Our display mode settings.
our $LIGHT_ON     = 1;
our $BLEND_ON     = 0;
our $TEXTURE_ON   = 1;
our $FILTERING_ON = 1;
our $ALPHA_ADD    = 0;

our $TEXTURE_MODE = GL_MODULATE;

our @texture_mode = (GL_DECAL, GL_MODULATE, GL_BLEND, GL_REPLACE);
our @texture_mode_str = qw(GL_DECAL GL_MODULATE GL_BLEND GL_REPLACE);

1;

=pod

=head1 NAME

OpenGL::Earth

=head1 SYNOPSIS

Mmh... I don't think you can use this module directly.
Better look at the C<bin> folder.

=head1 DESCRIPTION

It's an attempt to write an OpenGL Perl program that can display
a fancy rotating planet, while also displaying useful
geographic information on it.

The development stage is really early now.
Don't expect miracles.

It's basically a 10-years old OpenGL C program, translated
to Perl like 8 years ago, and then butchered and reassembled
by yours truly during some nightly hacking sessions.

=head1 AUTHORS

Cosimo Streppone, <cosimo@cpan.org>

=head1 COPYRIGHT

This code comes with the same terms as Perl itself.

=cut

