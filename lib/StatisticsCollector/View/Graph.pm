package StatisticsCollector::View::Graph;
use Moose;
use Imager::Graph::StackedColumn;
use Imager::Font;

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

    my $font = Imager::Font->new(file => '/Library/Fonts/Arial.ttf')
        or die "Imager Error: $!";

    my $graph = Imager::Graph::StackedColumn->new();

    my $y_max = $c->stash->{y_max} // 20;
    my $y_min = $c->stash->{y_min} // 0;

    my $delta = 1;
    my $ticks = 9999;
    my $count = 0;
    while ($ticks > 10 && $count < 100) {
        $y_max = int(($y_max + (9 * $delta)) / (10 * $delta)) * (10 * $delta);
        $y_max = 10 if $y_max < 10;

        $y_min = int(($y_min - (9 * $delta)) / (10 * $delta)) * (10 * $delta);
        $y_min = 0 if $y_min > 0;

        $ticks = int(($y_max - $y_min) / (5 * $delta)) + 1;
        if ($ticks > 10) {
            $ticks = int(($y_max - $y_min) / (10 * $delta)) + 1
        }

        if ($ticks > 20) {
            $delta *= 10;
        }

        # $c->log->warn("min=$y_min, max=$y_max, ticks=$ticks, delta=$delta");
        $count++;
    }

    # $c->log->debug("AFTER min=$y_min, max=$y_max");

    $graph->add_data_series( @{$_} ) for @{ $c->stash->{data} };

    $graph->set_style('fount_lin');
    $graph->show_horizontal_gridlines();
    $graph->use_automatic_axis();
    $graph->set_y_max($y_max);
    $graph->set_y_min($y_min);
    $graph->set_y_tics($ticks);
    $graph->set_image_width($c->stash->{width}   // 600);
    $graph->set_image_height($c->stash->{height} // 400);
    $graph->set_title_font_size(24);

    my $img = $graph->draw(
        features       => [ 'horizontal_gridlines', 'areamarkers' ],
        column_padding => 20,
        labels         => $c->stash->{labels},
        title          => $c->stash->{title} // 'Untitled',
        font           => $font,
        hgrid          => { style => "dashed", color => "#888" },
        graph          => { outline => { color => "#F00", style => "dotted" }, },
        fills          => [
            #  red:max  blue:min (was green: 60ff60)
            qw(ffb0b0   b0b0ff),
        ],
        
        # changed from defaults of fount_lin
        back           => {
            fountain => 'linear',
            xa_ratio => 0.0, ya_ratio => 0.0,
            xb_ratio => 0.0, yb_ratio => 1.0,
            segments => Imager::Fountain->simple( 
                positions => [0, 1],
                colors => [ 'c0c0ff', 'e0e0FF' ])
        },
    ) or die $graph->error;

    my $data;
    $img->write( data => \$data, type => 'png' );

    $c->response->body($data);
    $c->response->content_type('image/png');
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
