use strict;
use warnings;
package Dist::Zilla::Plugin::TrialVersionComment;
# ABSTRACT: Add a # TRIAL comment after your version declaration in trial # releases
# KEYWORDS: plugin modules package version comment trial release
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with
    'Dist::Zilla::Role::PPI',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' =>
        { default_finders => [ ':InstallModules', ':ExecFiles' ] },
;
use namespace::autoclean;

sub munge_files
{
    my $self = shift;

    $self->log_debug([ 'release_status is not trial; doing nothing' ]), return
        if not $self->zilla->is_trial;

    foreach my $file ( @{ $self->found_files })
    {
        next if $file->is_bytes;
        next if not $file->does('Dist::Zilla::Role::MutableFile');

        # it would be nice if we could just ask Module::Metadata for the line
        # (and character offset!) that it already found - might be faster

        my $document = $self->ppi_document_for_file($file);

        my $package_stmts = $document->find('PPI::Statement::Package');
        $self->log_debug([ 'skipping %s: no package statement found', $file->name ]), return
            if not $package_stmts;

        my %seen_pkg;

        my $munged = 0;
        for my $stmt (@$package_stmts)
        {
            my $package = $stmt->namespace;
            $self->log_debug([ 'skipping package re-declaration for %s', $package ]), next
                if $seen_pkg{ $package }++;

            # note: keep in sync with Dist::Zilla::Role::PPI::document_assigns_to_variable
            my $finder = sub {
                my $node = $_[1];
                return 1 if $node->isa('PPI::Statement')
                    && !$node->isa('PPI::Statement::End')
                    && !$node->isa('PPI::Statement::Data')
                    && $node->content =~ /^[^#]*(?<!\\)\$VERSION\s*=/sm
                    && $node->parent->content !~ /;\h*#\s*TRIAL/;   # no existing comment on line
            };

            my $node = $document->find_first($finder);
            $self->log_debug([ '%s does not set $VERSION; skipping', $file->name ]), next
                if not $node;

            $self->log_debug([ 'Adding # TRIAL to $VERSION line for %s', $file->name ]);

            # inserted in reverse order... can I insert both at the same time?
            $node->insert_after(PPI::Token::Comment->new('# TRIAL'));
            $node->insert_after(PPI::Token::Whitespace->new(' '));
            $munged = 1;
        }

        $self->save_ppi_document_to_file($document, $file) if $munged;
    }
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [TrialVersionComment]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that  munges your F<.pm> files to add a
C<# TRIAL> comment after C<$VERSION> assignments, if the release is C<--trial>.

If the distribution is not a C<--trial> release (i.e. C<release_status> in
metadata is C<stable>), this plugin does nothing.

A C<$VERSION> assignment needs to exist in the module for any content to be
added, so you need to position this plugin in F<dist.ini> after any
C<$VERSION>-adding plugins such as
L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion> or
L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion>.

Nothing currently parses these comments, but the idea is that things like
L<Module::Metadata> might make use of this in the future.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-TrialVersionComment>
(or L<bug-Dist-Zilla-Plugin-TrialVersionComment@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-TrialVersionComment@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

Inspiration for this module came about through multiple toolchain conversations with David Golden (xdg).

=head1 SEE ALSO

=for :list
* L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion>
* L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion>
* L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
* L<[OverridePkgVersion]|Dist::Zilla::Plugin::OverridePkgVersion>
* L<[SurgicalPkgVersion]|Dist::Zilla::Plugin::SurgicalPkgVersion>
* L<[PkgVersionIfModuleWithPod]|Dist::Zilla::Plugin::PkgVersionIfModuleWithPod>

=cut
