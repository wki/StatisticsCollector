package StatisticsCollector::Controller::Graph;
use Moose;
use List::Util qw(min max);
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

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body(
        'Matched StatisticsCollector::Controller::Graph in Graph.');
}

=head2 error

=cut

sub error :Action {
    my ($self, $c, $message) = @_;
    $c->res->content($message // 'An error occured');
    $c->res->code(500);
}

=head2 base

base of all chains defined here

=cut

sub base :Chained :PathPrefix :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 sensor

startpoint of a common chain allowing to specify the sensor to show the graph for

=cut

sub sensor :Chained('base') :CaptureArgs(1)  {
    my ( $self, $c, $sensor_id ) = @_;

    $c->stash->{sensor} = $c->model('DB::Sensor')->find($sensor_id)
        or $c->detach(error => ["Could not find sensor $sensor_id"]);
}

=head2 hours

create hourly bar charts for a given sensor

URL: /graph/sensor/<sensor_id>/hours [ / <nr_of_hours>]

=cut

sub hours :Chained('sensor') {
    my ( $self, $c, $nr_of_hours ) = @_;

    $nr_of_hours = 12 if !$nr_of_hours || $nr_of_hours < 5 || $nr_of_hours > 48;

    my $sensor = $c->stash->{sensor};

    my @measures = $sensor->aggregate_measures('hour', $nr_of_hours);

    my @labels = map { $_->starting_at->hour }
                 @measures;

    $c->forward('construct_graph', [\@measures, \@labels]);
}

=head2 days

create daily bar charts for a given sensor

URL: /graph/sensor/<sensor_id>/days [ / <nr_of_days>]

=cut

sub days :Chained('sensor') {
    my ( $self, $c, $nr_of_days ) = @_;

    $nr_of_days = 7 if !$nr_of_days || $nr_of_days < 5 || $nr_of_days > 35;

    my $sensor = $c->stash->{sensor};

    my @measures = $sensor->aggregate_measures('day', $nr_of_days);
    my @day_of_week = ('?', split(//, 'MTWTFSS'));

    my @labels = map { $day_of_week[ $_->starting_at->day_of_week ] }
                 @measures;

    $c->forward('construct_graph', [\@measures, \@labels]);
}

=head2 weeks

create weekly bar charts for a given sensor

URL: /graph/sensor/<sensor_id>/weeks [ / <nr_of_weeks>]

=cut

sub weeks :Chained('sensor') {
    my ( $self, $c, $nr_of_weeks ) = @_;

    $nr_of_weeks = 12 if !$nr_of_weeks || $nr_of_weeks < 8 || $nr_of_weeks > 30;

    my $sensor = $c->stash->{sensor};

    my @measures = $sensor->aggregate_measures('week', $nr_of_weeks);

    my @labels = map { $_->starting_at->week_number }
                 @measures;

    $c->forward('construct_graph', [\@measures, \@labels]);
}

=head2 months

create monthly bar charts for a given sensor

URL: /graph/sensor/<sensor_id>/months [ / <nr_of_months>]

=cut

sub months :Chained('sensor') {
    my ( $self, $c, $nr_of_months ) = @_;

    $nr_of_months = 12 if !$nr_of_months || $nr_of_months < 8 || $nr_of_months > 24;

    my $sensor = $c->stash->{sensor};

    my @measures = $sensor->aggregate_measures('month', $nr_of_months);

    my @labels = map { $_->starting_at->month }
                 @measures;

    $c->forward('construct_graph', [\@measures, \@labels]);
}

=head2 construct_graph

common handling for graph building. Receives measures and labels

=cut

sub construct_graph :Private {
    my ($self, $c, $measures, $labels) = @_;

    my $sensor = $c->stash->{sensor};

    my (@min, @max, @avg, @sum, @nr);
    foreach my $measure (@{$measures}) {
        if (defined($measure->min_value)) {
            push @min, $measure->min_value;
            push @max, $measure->max_value - $measure->min_value;
            push @avg, $measure->sum_value / $measure->nr_values;
            push @sum, $measure->sum_value;
            push @nr,  $measure->nr_values;
        } else {
            push @min, undef;
            push @max, undef;
            push @avg, undef;
            push @sum, undef;
            push @nr,  undef;
        }
    }

    my @data;
    if ($sensor->default_graph_type eq 'avg') {
        push @data, [ \@avg, 'avg' ];
    } else {
        push @data, [ \@max, 'max' ];
        push @data, [ \@min, 'min' ];
    }

    $c->stash(
        title    => $sensor->name,
        width    => 600,
        height   => 400,
        data     => \@data,
        y_max    => max(_values_of(@data)),
        y_min    => min(_values_of(@data)),
        labels   => $labels,
    );

    $c->forward( 'View::Graph' );
}

sub _values_of {
    grep defined, map { @{$_->[0]} } @_
}

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
