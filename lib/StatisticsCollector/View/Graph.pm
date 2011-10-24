package StatisticsCollector::View::Graph;
use Moose;
use Imager::Graph::StackedColumn;

# use Imager::Font;

use namespace::autoclean;

extends 'Catalyst::View';

=head1 NAME

StatisticsCollector::View::Graph - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 METHODS

=cut

=head2 process

called by Catalyst as soon as this view is invoked

=cut

sub process {
    my ( $self, $c ) = @_;

    my $font = Imager::Font->new( file => '/Library/Fonts/Arial.ttf' )
      || die "Error: $!";

    my $graph = Imager::Graph::StackedColumn->new();

    $graph->add_data_series( @{$_} ) for @{ $c->stash->{data} };

    $graph->show_horizontal_gridlines();
    $graph->set_y_tics(5);

    my $img = $graph->draw(
        image_width    => $c->stash->{width}  // 600,
        image_height   => $c->stash->{height} // 400,
        features       => [ "horizontal_gridlines", "areamarkers" ],
        column_padding => 20,
        y_min          => 0,
        y_max          => 20,
        labels         => $c->stash->{labels},
        title          => $c->stash->{title} // 'Untitled',
        font           => $font,
        hgrid          => { style => "dashed", color => "#888" },
        graph          => { outline => { color => "#F00", style => "dotted" }, },

    ) || die $graph->error;

    my $data;
    $img->write( data => \$data, type => 'png' );

    $c->response->body($data);
    $c->response->content_type('image/png');
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
