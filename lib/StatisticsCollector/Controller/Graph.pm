package StatisticsCollector::Controller::Graph;
use Moose;
use Imager::Graph;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

StatisticsCollector::Controller::Graph - Catalyst Controller

=head1 DESCRIPTION

generate Graph Images

=head1 METHODS

=cut

=head2 end

empty end action that replaces Root's end

=cut

sub end :Private {}

=head2 index

maybe unneccesary -- we will see

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body(
        'Matched StatisticsCollector::Controller::Graph in Graph.');
}

=head2 base

base of all chains defined here

=cut

sub base :Chained('/') :PathPrefix {
    my ( $self, $c ) = @_;
}

=head2 sensor

startpoint of a common chain allowing to specify the sensor to show the graph for

=cut

sub sensor :Chained('base') :CaptureArgs(1)  {
    my ( $self, $c, $sensor_id ) = @_;

    $c->stash->{sensor} = $c->model('DB::Sensor')->find($sensor_id)
      or die "Could not find sensor $sensor_id";
}

=head2 bar

create bar charts for a given sensor

URL: /graph/<sensor_id>/bar

=cut

sub bar :Chained('sensor') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title    => 'erlangen keller temperatur',
        width    => 300,
        height   => 200,
        data     => [ 
            [ [ 1, 2, 1, 3, 1, 0, 1 ], 'max' ], # actually: max - min
            [ [ 1, 2, 3, 6, 5, 7, 3 ], 'min' ],
        ],
        labels   => [ qw(M T W T F S S) ],
    );
    
    $c->forward( 'View::Graph' );
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
