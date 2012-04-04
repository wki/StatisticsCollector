package StatisticsCollector::Schema::Result::Sensor;
use DBIx::Class::Candy;
use DateTime;
use DateTime::Duration;
use List::Util qw(min max);

=head1 NAME

StatisticsCollector::Schema::Result::Sensor - Table definition

=head1 SYNOPSIS

    my $sensor = $schema->resultset('Sensor')->find(42);
    $sensor->add_measure(32);
    
    my @agg = $sensor->aggregate_measures(hour => 24);

=head1 DESCRIPTION

A Sensor describes the source of measures.

=head1 TABLE

sensor

=cut

table 'sensor';

=head1 COLUMNS

=cut

=head2 sensor_id

primary key

=cut

primary_column sensor_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

=head2 name

a unique 3-part "/" divided name for a sensor

=cut

unique_column name => {
    data_type => 'text',
    is_nullable => 0,
    default_value => '',
};

=head2 active

a boolean indicating if this sensor is still in use

=cut

column active => {
    data_type => 'boolean',
    is_nullable => 0,
    default_value => 1,
};

=head2 default_graph_type

controls which graph to generate from aggregated values.

Possible entries are:

=over

=item avg

=item min

=item max

=item sum

=back

=cut

column default_graph_type => {
    data_type => 'text',
    is_nullable => 0,
    default_value => 'avg',
};

=head1 RELATIONS

=cut

=head2 measures

A L<Sensor|StatisticsCollector::Schema::Result::Sensor> 
might mave many L<Measures|StatisticsCollector::Schema::Result::Measure>,
every L<Measure|StatisticsCollector::Schema::Result::Measure> belongs to 
exactly one L<Sensor|StatisticsCollector::Schema::Result::Sensor>

=cut

has_many measures => 'StatisticsCollector::Schema::Result::Measure', 'sensor_id';

=head2 latest_measures

A L<Sensor|StatisticsCollector::Schema::Result::Sensor> might mave a 
L<LatestMeasure|StatisticsCollector::Schema::Result::LatestMeasure>
Every L<LatestMeasure|StatisticsCollector::Schema::Result::Measure> belongs to 
exactly one L<Sensor|StatisticsCollector::Schema::Result::Sensor>

=cut

might_have latest_measure => 'StatisticsCollector::Schema::Result::LatestMeasure', 'sensor_id';

=head2 alarms

=cut

has_many alarms => 'StatisticsCollector::Schema::Result::Alarm', 'alarm_condition_id';

=head1 METHODS

=cut

=head2 add_measure( $value )

a convenience method allowing to simply add new measures to a sensor.

=cut

sub add_measure {
    my $self  = shift;
    my $value = shift // 0;
    
    my $this_hour = DateTime->now( time_zone => 'local' )
                            ->truncate( to => 'hour' );
    my $next_hour = $this_hour->clone->add( hours => 1 );

    my $formatter = $self->result_source->schema->storage->datetime_parser;

    my $measure_for_this_hour =
        $self->search_related('measures', 
                              {
                                  starting_at => { '>=' => $formatter->format_datetime($this_hour) },
                                  ending_at   => { '<=' => $formatter->format_datetime($next_hour) },
                              } )
             ->first;

    if ($measure_for_this_hour) {
        $measure_for_this_hour->update(
            {
                latest_value => $value,
                min_value    => min($measure_for_this_hour->min_value, $value),
                max_value    => max($measure_for_this_hour->max_value, $value),
                sum_value    => $measure_for_this_hour->sum_value() + $value,
                nr_values    => $measure_for_this_hour->nr_values() + 1,
            });
    } else {
        $measure_for_this_hour =
            $self->create_related(
                     measures =>
                     {
                         latest_value  => $value,
                         min_value     => $value,
                         max_value     => $value,
                         sum_value     => $value,
                         nr_values     => 1,
                         starting_at   => $this_hour,
                         ending_at     => $next_hour,
                     } );
    }

    return $measure_for_this_hour;
}

=head2 aggregate_measures($interval, $nr_of_samples)

returns a list containing $nr_of_samples entries. Each entry represents
a given interval. Possible intervals are:

=over

=item hour

=item day

=item week

=item month

=item year

=back

=cut

sub aggregate_measures {
    my $self = shift;
    my $unit = shift || 'day';
    my $nr_samples = shift || 10;
    
    return $self->result_source->schema->resultset('AggregateMeasure')
                ->search( undef, { bind => [$unit, $nr_samples, $self->id] } );
}

1;

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
