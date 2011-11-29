package StatisticsCollector::View::SVG;

use strict;
use warnings;
use parent 'Catalyst::View::SVG::TT::Graph';

__PACKAGE__->config( {
    # format     => "png",
    # show_graph_title => 1
} );

=head1 NAME

StatisticsCollector::View::SVG - SVG View for StatisticsCollector

=head1 DESCRIPTION

SVG::TT::Graph View for StatisticsCollector.

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

