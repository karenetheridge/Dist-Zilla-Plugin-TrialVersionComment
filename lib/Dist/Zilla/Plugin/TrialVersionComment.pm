use strict;
use warnings;
package Dist::Zilla::Plugin::TrialVersionComment;
# ABSTRACT: ...
# KEYWORDS: ...
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::...';

use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [TrialVersionComment]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that...

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-TrialVersionComment>
(or L<bug-Dist-Zilla-Plugin-TrialVersionComment@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-TrialVersionComment@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
