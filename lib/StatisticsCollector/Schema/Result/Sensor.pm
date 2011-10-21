package StatisticsCollector::Schema::Result::Sensor;
use DBIx::Class::Candy;
use DateTime;
use DateTime::Duration;
use List::Util qw(min max);

table 'sensor';

primary_column sensor_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

unique_column name => {
    data_type => 'text',
    is_nullable => 0,
    default_value => '',
};

has_many measures => 'StatisticsCollector::Schema::Result::Measure', 'sensor_id';
might_have latest_measure => 'StatisticsCollector::Schema::Result::LatestMeasure', 'sensor_id';

sub add_measure {
    my ($self, $value) = @_;

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

1;
