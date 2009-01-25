# $Id$

package OpenGL::Earth::Scene;

our @LIGHT_AMBIENT  = ( 0.0, 0.0, 0.1, 0.2 );
our @LIGHT_DIFFUSE  = ( 1.2, 1.2, 1.2, 1.0 );
our @LIGHT_POSITION = ( 4.0, 4.0, 2.0, 3.0);

sub light_ambient {
	return @LIGHT_AMBIENT;
}

sub light_diffuse {
	return @LIGHT_DIFFUSE;
}

sub light_position {
	return @LIGHT_POSITION;
}

1;

