use strict;use warnings;
use Module::Build;

my $builder = Module::Build->new(
    sign              => 1,
    module_name       => 'TV::ProgrammesSchedules::ZEE',
    license           => 'perl',
    dist_author       => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    dist_version_from => 'lib/TV/ProgrammesSchedules/ZEE.pm',
    add_to_cleanup    => [ 'TV-ProgrammesSchedules-ZEE-*' ],    
    build_requires    => {
        'Test::More'            => 0,
        'Readonly'              => 0,
        'HTTP::Request::Common' => 0,
        'Time::localtime'       => '1.02',
        'LWP::UserAgent'        => '2.33',
    },
);

$builder->create_build_script();