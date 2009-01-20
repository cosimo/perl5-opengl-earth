#!/usr/bin/env perl
#
# OpenGL texture-mapped Earth
# 08/12/2008 <cosimo@cpan.org>
#
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
use lib './lib';
use OpenGL q(:all);
use OpenGL::Earth::Coords;

use constant PROGRAM_TITLE => 'OpenGL Earth';

# Some global variables

my $earth_texture = '../textures/earth_4k2.texture';

# Window and texture IDs, window width and height.
my $Window_ID;
my $Window_Width = 600;
my $Window_Height = 600;
our @Texture_ID;

# Our display mode settings.
my $Light_On = 1;
my $Blend_On = 0;
my $Texture_On = 1;
my $Filtering_On = 1;
my $Alpha_Add = 0;

my $Curr_TexMode = GL_MODULATE;
my @TexModesStr = qw(GL_DECAL GL_MODULATE GL_BLEND GL_REPLACE);
my @TexModes = (GL_DECAL, GL_MODULATE, GL_BLEND, GL_REPLACE);

# Object and scene global variables.

# Cube position and rotation speed variables.
my $X_Rot   = 300;
my $Y_Rot   = 0.0;
my $X_Speed = 0.0;
my $Y_Speed = 0.1;
my $Z_Off   =-5.0;

# Settings for our light.  Try playing with these (or add more lights).
my @Light_Ambient  = ( 0.0, 0.0, 0.1, 0.2 );
my @Light_Diffuse  = ( 1.2, 1.2, 1.2, 1.0 );
my @Light_Position = ( 4.0, 4.0, 2.0, 3.0);

our @network_hits = ();

# Check-up grid
#
#for (my $x = -180; $x <= 180; $x += 10) {
#	for (my $y = -90; $y <= 90; $y += 10) {
#		push @spikes, [ $y, $x, 10 ];
#	}
#}

=cut
# ------
# Frames per second (FPS) statistic variables and routine.

use constant CLOCKS_PER_SEC => 1000;
use constant FRAME_RATE_SAMPLES => 50;

my $FrameCount = 0;
my $FrameRate = 0;
my $last=0;

sub ourDoFPS {
  my $now;
  my $delta;

  if (++$FrameCount >= FRAME_RATE_SAMPLES) {
     $now  = Win32::GetTickCount(); # clock();
     $delta= ($now - $last) / CLOCKS_PER_SEC;
     $last = $now;

     $FrameRate = FRAME_RATE_SAMPLES / $delta;
     $FrameCount = 0;
  }
}
=cut

sub display_spike {
  my ($lat, $long, $amount, $radius) = @_;

  # Apply texture offset
  $long -= 90;

  my ($x1, $y1, $z1) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long, $radius + $amount/200);
  my ($x2, $y2, $z2) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long + 0.4, $radius);
  my ($x3, $y3, $z3) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long - 0.4, $radius);

  glBegin(GL_TRIANGLES);
      glColor3f(1.0, 0.3, 0.3);
      glVertex3f($x1, $y1, $z1);
      glVertex3f($x2, $y2, $z2);
      glVertex3f($x3, $y3, $z3);
  glEnd();

  #glLineWidth(1);
  #glBegin(GL_LINES);
  #    glColor4f(1.0, 0.2, 0.2, 0.6);
  #    glVertex3f(0, 0, 0);
  #    glVertex3f($x1, $y1, $z1);
  #glEnd();

  return;
}

# ------
# String rendering routine; leverages on GLUT routine.

sub ourPrintString {
  my ($font, $str) = @_;
  my @c = split '', $str;

  for(@c) {
    glutBitmapCharacter($font, ord $_);
  }
}

sub display_spikes {

	# Get one more spike
	#if (1) { #! eof(STDIN)) {
    #my $line = <STDIN>;
    #my ($ip) = split(' ', $line, 2);
    #my ($a, $b, $c, $d) = split m{\.}, $ip;
    for (1..5) {
        my $lon = rand(360) - 180;
        my $lat = rand(180) - 90;
        push @network_hits, [ $lat, $lon, 100 ];
    }
	#}

    for my $s (@network_hits) {
        display_spike($s->[0], $s->[1], $s->[2], 1.5);
		$s->[2] -= 4;
    }

    @network_hits = grep { $_->[2] > 0 } @network_hits;

}

# ------
# Routine which actually does the drawing

sub cbRenderScene {
  my $buf; # For our strings.

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

  display_spikes();

  # Move back to the origin (for the text, below).
  glLoadIdentity();

  # We need to change the projection matrix for the text rendering.
  glMatrixMode(GL_PROJECTION);

  # But we like our current view too; so we save it here.
  glPushMatrix();

  # Now we set up a new projection for the text.
  glLoadIdentity();
  glOrtho(0,$Window_Width,0,$Window_Height,-1.0,1.0);

  # Lit or textured text looks awful.
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);
  glDisable(GL_LIGHTING);

  # We don'$t want depth-testing either.
  glDisable(GL_DEPTH_TEST);

  # But, for fun, let's make the text partially transparent too.
  glColor4f(0.6,1.0,0.6,.75);

  # Render our various display mode settings.
  $buf = sprintf "Mode: %s", $TexModesStr[$Curr_TexMode];
  glRasterPos2i(2,2); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "AAdd: %d", $Alpha_Add;
  glRasterPos2i(2,14); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Blend: %d", $Blend_On;
  glRasterPos2i(2,26); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Light: %d", $Light_On;
  glRasterPos2i(2,38); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Tex: %d", $Texture_On;
  glRasterPos2i(2,50); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Filt: %d", $Filtering_On;
  glRasterPos2i(2,62); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);


  # Now we want to render the calulated FPS at the top.
  # To ease, simply translate up.  Note we're working in screen
  # pixels in this projection.
  #  
  #glTranslatef(6.0,$Window_Height - 14,0.0);
  #  
  # Make sure we can read the FPS section by first placing a
  # dark, mostly opaque backdrop rectangle.
  #glColor4f(0.0, 0.0, 0.0, 0.75);
  #  
  #glBegin(GL_QUADS);
  #glVertex3f(  0.0, -2.0, 0.0);
  #glVertex3f(  0.0, 12.0, 0.0);
  #glVertex3f(140.0, 12.0, 0.0);
  #glVertex3f(140.0, -2.0, 0.0);
  #glEnd();

  #glColor4f(0.9, 0.0, 0.0, .75);
  #$buf = sprintf "FPS: %f F: %2d", $FrameRate, $FrameCount;
  #glRasterPos2i(6,0);
  #ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  # Done with this special projection matrix.  Throw it away.
  glPopMatrix();

  # All done drawing.  Let's show it.
  glutSwapBuffers();

  # Now let's do the motion calculations.
  $X_Rot += $X_Speed;
  $Y_Rot += $Y_Speed;

  # And collect our statistics.
  #ourDoFPS();
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
  open(my $texf, '<', $earth_texture) or
    do {
        glutDestroyWindow($Window_ID);
        die "Can't open Earth texture '$earth_texture': $!\n"
    };

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

