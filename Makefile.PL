use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'OpenGL::Earth',
    VERSION_FROM    => 'lib/OpenGL/Earth.pm',
    PREREQ_PM       => {
        'OpenGL'                => '0.57',
        'Linux::Input::Wiimote' => '0',
    },
	NO_META			=> 1,
    ($] >= 5.005 ?
        (AUTHOR     => 'Cosimo Streppone <cosimo@cpan.org>') : ()),
);
