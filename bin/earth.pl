#!/usr/bin/env perl
#
# OpenGL texture-mapped Earth
# 08/12/2008 <cosimo@cpan.org>
#
# -----------------------------------------------------------------
# Originally based on OpenGL cube demo written by
# Chris Halsall (chalsall@chalsall.com) for the
# O'Reilly Network on Linux.com (oreilly.linux.com).
# May 2000.
#
# Released into the Public Domain; do with it as you wish.
# We would like to hear about interesting uses.
#
# Translated from C to Perl by J-L Morel <jl_morel@bribes.org>
# (http://www.bribes.org/perl/wopengl.html)
#
# $Id$

BEGIN { $| = 1 }

use strict;
use lib '../lib';

use OpenGL q(:all);
use OpenGL::Earth;
use OpenGL::Earth::Coords;
use OpenGL::Earth::NetworkHits;
use OpenGL::Earth::Render;
use OpenGL::Earth::Scene;
use OpenGL::Earth::Wiimote;

use constant PROGRAM_TITLE => 'OpenGL Earth';

# Object and scene global variables.

# Cube position and rotation speed variables.
my $X_Rot   = 300;
my $Y_Rot   = 0.0;
my $X_Speed = 0.0;
my $Y_Speed = 0.02;
my $Z_Off   =-5.0;

our @network_hits = ();

# ------
# Routine which actually does the drawing

sub cbRenderScene {

  # Enables, disables or otherwise adjusts as
  # appropriate for our current settings.

  if ($Texture_On) {
    glEnable(GL_TEXTURE_2D);
  }
  else {
    glDisable(GL_TEXTURE_2D);
  }
  if ($Light_On) {
    glEnable(GL_LIGHTING);
  }
  else {
    glDisable(GL_LIGHTING);
  }

  #if ($Alpha_Add) {
  #  glBlendFunc(GL_SRC_ALPHA,GL_ONE);
  #}
  #else {
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  #}

  # If we're blending, we don'$t want z-buffering.
  if ($Blend_On) {
    glDisable(GL_DEPTH_TEST);
  }
  else {
    glEnable(GL_DEPTH_TEST);
  }
  if ($Filtering_On) {
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  }
  else {
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
  }

  # Need to manipulate the ModelView matrix to move our model around.
  glMatrixMode(GL_MODELVIEW);

  # Reset to 0,0,0; no rotation, no scaling.
  glLoadIdentity();

  # Move the object back from the screen.
  glTranslatef(0.0,0.0,$Z_Off);

  # Rotate the calculated amount.
  glRotatef($X_Rot,1.0,0.0,0.0);
  glRotatef($Y_Rot,0.0,0.0,1.0);

  # Clear the color and depth buffers.
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  my $quad = gluNewQuadric();
  if ($quad != 0)
  {
      gluQuadricNormals($quad, GLU_SMOOTH);
      gluQuadricTexture($quad, GL_TRUE);
 
      #my @Earth_emission = (0.0, 0.0, 0.0, 1.0);
      #my @Earth_specular = (0.3, 0.3, 0.3, 1.0);
      #glMaterialf(GL_FRONT, GL_EMISSION, 0.0); #@Earth_emission);
      #glMaterialf(GL_FRONT, GL_SPECULAR, 50.0); #@Earth_specular);

      # Render Earth sphere
      glBindTexture(GL_TEXTURE_2D, $Texture_ID[0]);
      glColor3f(0.6, 0.6, 0.6);

      gluSphere($quad, 1.5, 64, 64);
      gluDeleteQuadric($quad);
  }

=cut
  # Render Earth atmosphere and clouds
  glBindTexture(GL_TEXTURE_2D, $Texture_ID[1]);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glColor4f(1.0, 1.0, 1.0, 0.7);
  if ($quad = gluNewQuadric()) {
      gluQuadricNormals($quad, GLU_SMOOTH);
      gluQuadricTexture($quad, GL_TRUE);
      gluSphere($quad, 1.501, 64, 64);
      gluDeleteQuadric($quad);
  }
  glDisable(GL_BLEND);
=cut

  glDisable(GL_LIGHTING);

  OpenGL::Earth::NetworkHits::display(\@network_hits);

  # Sense the wii motion
  my $motion = OpenGL::Earth::Wiimote::get_motion($wii);

  # Move back to the origin (for the text, below).
  glLoadIdentity();

  OpenGL::Earth::Render::text_stats();

  # All done drawing.  Let's show it.
  glutSwapBuffers();

  #static_motion_calc($motion);
  falloff_motion_calc($motion);

  # And collect our statistics.
  #ourDoFPS();
}

sub falloff_motion_calc {
	my ($motion) = @_;

	my $falloff_factor = 0.98;
	my $acc = abs($motion->{force_x} / 10);

    my $keys = OpenGL::Earth::Wiimote::get_keys($wii);
	my $acc_pos = exists $keys->{A};
	my $home = exists $keys->{home};

	if ($home) {
		$X_Rot = 300.0;
		$Y_Rot = 0.0;
		$X_Speed = 0.00;
		$Y_Speed = 0.02;
		return;
	}

	if (exists $keys->{up}) {
		$Z_Off -= 0.01;
	}
	if (exists $keys->{down}) {
		$Z_Off += 0.01;
	}

	if ($acc_pos) {
		$X_Speed += $acc * ($X_Speed > 0 ? 1 : -1);
		$Y_Speed += $acc * ($Y_Speed > 0 ? 1 : -1);
	}
	else {
		$X_Speed += $motion->{tilt_z} * $acc;
		$Y_Speed += $motion->{tilt_y} * $acc;
	}

	if ($X_Speed > 1) { $X_Speed = 1 }
	if ($Y_Speed > 1) { $Y_Speed = 1 }

	$X_Rot += $X_Speed;
	$Y_Rot += $Y_Speed;

	$X_Speed *= $falloff_factor;
	$Y_Speed *= $falloff_factor;

	return;
}

{
	my $prev_tilt_x = 0.0;
	my $prev_tilt_y = 0.0;

	sub static_motion_calc {

		my ($motion) = @_;

		# Now let's do the motion calculations.
		$X_Speed = ($motion->{tilt_z} - $prev_tilt_x) / 2;
		$Y_Speed = ($motion->{tilt_y} - $prev_tilt_y) / 2;

		$prev_tilt_x = $X_Speed;
		$prev_tilt_y = $Y_Speed;

		$X_Rot += $X_Speed;
		$Y_Rot += $Y_Speed;

		return;
	}

}


# ------
# Callback function called when a normal $key is pressed.

sub cbKeyPressed {
  my $key = shift;
  my $c = uc chr $key;
  if ($key == 27 or $c eq 'Q') {
    glutDestroyWindow($Window_ID);
    exit(1);
  }
  elsif ($c eq 'B' ) { # B - Blending.
    $Blend_On = $Blend_On ? 0 : 1;
    if (!$Blend_On) {
      glDisable(GL_BLEND);
    }
    else {
      glEnable(GL_BLEND);
    }
  }
  elsif ($c eq 'L') {        # L - Lighting
    $Light_On = $Light_On ? 0 : 1;
  }
  elsif ($c eq 'M') {        # M - Mode of Blending
    if ( ++ $Curr_TexMode > 3 ) {
      $Curr_TexMode=0;
    }
    glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,$TexModes[$Curr_TexMode]);
  }
  elsif ($c eq 'T') {        # T - Texturing.
    $Texture_On = $Texture_On ? 0 : 1;
  }
  elsif ($c eq 'A') {        # A - Alpha-blending hack.
    $Alpha_Add = $Alpha_Add ? 0 : 1;
  }
  elsif ($c eq 'F') {        # F - Filtering.
    $Filtering_On = $Filtering_On ? 0 : 1;
  }
  elsif ($c eq 'S' or $key == 32) {  # S (Space) - Freeze!
    $X_Speed=$Y_Speed=0;
  }
  elsif ($c eq 'R') {        # R - Reverse.
    $X_Speed = -$X_Speed;
    $Y_Speed = -$Y_Speed;
  }
  else {
    printf "KP: No action for %d.\n", $key;
  }
}

# ------
# Callback Function called when a special $key is pressed.

sub cbSpecialKeyPressed {
  my $key = shift;

  if ($key == GLUT_KEY_PAGE_UP) { # move the cube into the distance.
    $Z_Off -= 0.05;
  }
  elsif ($key == GLUT_KEY_PAGE_DOWN) { # move the cube closer.
    $Z_Off += 0.05;
  }
  elsif ($key == GLUT_KEY_UP) { # decrease $x rotation speed;
    $X_Speed -= 0.01;
  }
  elsif ($key == GLUT_KEY_DOWN) { # increase $x rotation speed;
    $X_Speed += 0.01;
  }
  elsif ($key == GLUT_KEY_LEFT) { # decrease $y rotation speed;
    $Y_Speed -= 0.01;
  }
  elsif ($key == GLUT_KEY_RIGHT) { # increase $y rotation speed;
    $Y_Speed += 0.01;
  }
  else {
    printf "SKP: No action for %d.\n", $key;
  }
}

# ------
# Function to build a simple full-color texture with alpha channel,
# and then create mipmaps.  This could instead load textures from
# graphics files from disk, or render textures based on external
# input.

sub ourBuildTextures {
  my $gluerr;

  # Generate a texture index, then bind it for future operations.
  @Texture_ID = glGenTextures_p(1);
  glBindTexture(GL_TEXTURE_2D, $Texture_ID[0]);

  # Iterate across the texture array.
  open my $texf, '<', '../textures/earth.texture';
  binmode $texf;
  my $tex = q{};
  my $buf;
  while (sysread($texf, $buf, 1048576)) {
    $tex .= $buf;
  }

  my $tex_w = 4096;
  my $tex_h = 2048;

=cut
  use Imager;

  my $scanline;
  my $tex = q{};
  my $earth_pic = Imager->new();
  print "Reading earth pic...\n";

  $earth_pic->read(file=>'earth_4k2.bmp') or die "Can't read texture!\n";

  print "Reading scanlines... ";
  my $tex_w = $earth_pic->getwidth();
  my $tex_h = $earth_pic->getheight();
  my $perc = 0;
  for (my $y = $tex_h - 1; $y >= 0; $y--) {
      $scanline = $earth_pic->getscanline(y=>$y);
      $tex .= $scanline;
      $perc = int (100 * ($tex_h - 1 - $y) / $tex_h);
      print "$perc%   \r";

  }
  print "\rTexture built.\n";

  open my $texf, '>', 'earth_4k2.texture'; 
  binmode $texf;
  print $texf $tex;
  close $texf;

=cut

  # The GLU library helps us build MipMaps for our texture.
  if ($gluerr = gluBuild2DMipmaps_s(GL_TEXTURE_2D, 4, $tex_w, $tex_h, GL_RGBA, GL_UNSIGNED_BYTE, $tex)) {
     printf STDERR "GLULib%s\n", gluErrorString($gluerr);
     exit(-1);
  }

  # Some pretty standard settings for wrapping and filtering.
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_R,GL_CLAMP);
  glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);

=cut
  glBindTexture(GL_TEXTURE_2D, $Texture_ID[1]);

  use Imager;

  $tex = q{};
  my $scanline;
  my $pic = Imager->new();
  print "Reading clouds pic...\n";

  $pic->read(file=>'clouds.bmp') or die "Can't read texture!\n";

  print "Reading scanlines...\n";
  $tex_w = $pic->getwidth();
  $tex_h = $pic->getheight();
  for (my $y = $tex_h - 1; $y >= 0; $y--) {
      $scanline = $pic->getscanline(y=>$y);
      for (0 .. length($scanline)/4 - 1) {
         my $red = ord substr($scanline, $_ * 4, 1);
         $red -= 100;
         if ($red < 0) { $red = 0 }
         if ($red > 100) { $red += ($red - 100) * 2 }
         if ($red > 255) { $red = 255 }
         substr($scanline, $_ * 4 + 3, 1, pack("C",$red));
      }
      $tex .= $scanline;
  }
  print "Clouds Texture built.\n";

  open my $texf, '>', 'clouds-texture.bin'; 
  binmode $texf;
  print $texf $tex;
  close $texf;

=cut

=cut
  open $texf, '<', 'clouds-texture.bin';
  binmode $texf;
  my $buf;
  $tex = q{};
  while (sysread($texf, $buf, 1048576)) {
    $tex .= $buf;
  }

  $tex_w = 1024;
  $tex_h = 512;

  # The GLU library helps us build MipMaps for our texture.
  if ($gluerr = gluBuild2DMipmaps_s(GL_TEXTURE_2D, 4, $tex_w, $tex_h, GL_RGBA, GL_UNSIGNED_BYTE, $tex)) {
     printf STDERR "GLULib%s\n", gluErrorString($gluerr);
     exit(-1);
  }

  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_R,GL_CLAMP);
  glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);

=cut

  return;
}

# ------
# Callback routine executed whenever our window is resized.  Lets us
# request the newly appropriate perspective projection matrix for
# our needs.  Try removing the gluPerspective() call to see what happens.

sub cbResizeScene {
  my ($Width, $Height) = @_;

  # Let's not core dump, no matter what.
  $Height = 1 if ($Height == 0);

  glViewport(0, 0, $Width, $Height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(45.0,$Width/$Height,0.1,100.0);

  glMatrixMode(GL_MODELVIEW);

  $Window_Width  = $Width;
  $Window_Height = $Height;
}

# ------
# Does everything needed before losing control to the main
# OpenGL event loop.

sub ourInit {
  my ($Width, $Height) = @_;

  $wii = OpenGL::Earth::Wiimote::init();

  ourBuildTextures();

  glutFullScreen();

  # Color to clear color buffer to.
  glClearColor(0.0, 0.0, 0.0, 0.0);

  # Depth to clear depth buffer to; type of test.
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);

  # Enables Smooth Color Shading; try GL_FLAT for (lack of) fun.
  glShadeModel(GL_SMOOTH);

  # Load up the correct perspective matrix; using a callback directly.
  cbResizeScene($Width, $Height);

  # Set up a light, turn it on.
  glLightfv_p(GL_LIGHT1, GL_POSITION, @Light_Position);
  glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @Light_Ambient);
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @Light_Diffuse);
  glEnable (GL_LIGHT1);

  glHint(GL_LINE_SMOOTH_HINT, GL_FASTEST);
  glEnable(GL_LINE_SMOOTH);

  # Another one
  #glLightfv_p(GL_LIGHT2, GL_POSITION, -5.0, -5.0, -10.0, 0.1);
  #glLightfv_p(GL_LIGHT2, GL_AMBIENT,  @Light_Ambient);
  #glLightfv_p(GL_LIGHT2, GL_DIFFUSE,  @Light_Diffuse);
  #glEnable (GL_LIGHT2);

  # A handy trick -- have surface material mirror the color.
  glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
  glEnable(GL_COLOR_MATERIAL);

}

# ------
# The main() function.  Inits OpenGL.  Calls our own init function,
# then passes control onto OpenGL.


glutInit();

# To see OpenGL drawing, take out the GLUT_DOUBLE request.
glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
glutInitWindowSize($Window_Width, $Window_Height);

# Open a window
$Window_ID = glutCreateWindow( PROGRAM_TITLE );

# Register the callback function to do the drawing.
glutDisplayFunc(\&cbRenderScene);

# If there's nothing to do, draw.
glutIdleFunc(\&cbRenderScene);

# It's a good idea to know when our window's resized.
glutReshapeFunc(\&cbResizeScene);

# And let's get some keyboard input.
glutKeyboardFunc(\&cbKeyPressed);
glutSpecialFunc(\&cbSpecialKeyPressed);

# OK, OpenGL's ready to go.  Let's call our own init function.
ourInit($Window_Width, $Window_Height);

# Print out a bit of help dialog.
print PROGRAM_TITLE, "\n";
print << 'TXT';
Use arrow keys to rotate, 'R' to reverse, 'S' to stop.
Page up/down will move the earth away from/towards camera.
Use first letter of shown display mode settings to alter.
Q or [Esc] to quit; OpenGL window must have focus for input.
TXT
;

# Pass off control to OpenGL.
# Above functions are called as appropriate.
glutMainLoop();

