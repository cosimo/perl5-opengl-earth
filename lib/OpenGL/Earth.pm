# $Id$

package OpenGL::Earth;

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

