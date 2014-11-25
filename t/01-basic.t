use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'TrialVersionComment' ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
our $VERSION = '0.001';
# TRIAL comment will be added above
1;
FOO
        },
    },
);

$tzil->is_trial(1);
$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/^our \$VERSION = '0\.001'; # TRIAL$/m,
    'TRIAL comment added to $VERSION assignment',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
