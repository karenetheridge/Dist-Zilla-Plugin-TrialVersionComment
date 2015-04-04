use strict;
use warnings;

use Test::Requires 'Dist::Zilla::Plugin::OurPkgVersion';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

# protect from external environment
local $ENV{TRIAL};

$ENV{TRIAL} = 1;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ OurPkgVersion => ],
                #[ 'TrialVersionComment' ], # not needed
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
# VERSION
# TRIAL comment will be added above, before the VERSION placeholder
1;
FOO
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

ok($tzil->is_trial, 'trial flag is set on the distribution');

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/\$\S*VERSION = '0\.001'; # TRIAL/m,
    'TRIAL comment added to $VERSION assignment by [OurPkgVersion]',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
