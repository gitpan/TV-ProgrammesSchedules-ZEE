use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'TV::ProgrammesSchedules::ZEE',
    AUTHOR        => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM  => 'lib/TV/ProgrammesSchedules/ZEE.pm',
    ABSTRACT_FROM => 'lib/TV/ProgrammesSchedules/ZEE.pm',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'TV-ProgrammesSchedules-ZEE-*' },
    PREREQ_PM     => {
        'Test::More'            => 0,
        'Readonly'              => 0,
        'HTTP::Request::Common' => 0,
        'Time::localtime'       => '1.02',
        'LWP::UserAgent'        => '2.33',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
);