use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

# protect from external environment
local $ENV{TRIAL};

my $original_content = <<'FOO';
package Foo;

# our $VERSION = '0.001'; # this line should be ignored

=pod

This file has one of these, but we shouldn't munge this one...

    our $VERSION = '0.002';

=cut
1;
FOO

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                { is_trial => 1 },  # merge into root section
                [ GatherDir => ],
                [ 'TrialVersionComment' => ],
            ),
            path(qw(source lib Foo.pm)) => $original_content,
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

is(
    $content,
    $original_content,
    'no real assignment was found to munge',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
