package StatisticsCollector::Schema::Result::AggregateMeasure;

use DBIx::Class::Candy 
    -components => [qw(InflateColumn::DateTime)];

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

=head1 NAME

StatisticsCollector::Schema::Result::AggregateMeasure - Virtual Table definition

=head1 SYNOPSIS

    # assume that $sensor holds a Sensor row
    my @measures = $sensor->aggregate_measures('hour', $nr_of_hours);

=head1 DESCRIPTION

Collects and aggregates a given number of 
L<Measures|StatisticsCollector::Schema::Result::Measure> 
into a given interval and returns the requested number of records.

=head1 TABLE

virtual_aggregate_measure (virtual table)

=cut

table 'virtual_aggregate_measure';

=head1 COLUMNS

=cut

=head2 sensor_id

=cut

column sensor_id => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 starting_at

=cut

column starting_at => {
    data_type => 'datetime', timezone => 'local',
};

=head2 ending_at

=cut

column ending_at => {
    data_type => 'datetime', timezone => 'local',
};

=head2 min_value

=cut

column min_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 max_value

=cut

column max_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 sum_value

=cut

column sum_value => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 nr_values

=cut

column nr_values => {
    data_type => 'int',
    is_nullable => 0,
};

=head1 RELATIONS

=cut

=head2 sensor

=cut

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';


__PACKAGE__->result_source_instance->is_virtual(1);

#
# this view contains 3 parameters that *must* be set by bind:
#   - unit:      'day', 'week', 'month'
#   - nr_values: number of sequence-values to generate
#   - sensor_id: the sensor to take measures for
#
# in order to enter every bind value only once, a 3-stage select is used:
#   - inner (=x)   gives unit and a series from 1..n
#   - mid (=range) yields starting_at and ending_at timestamps
#   - outer        generates the aggregates wanted
#
__PACKAGE__->result_source_instance->view_definition(q{
select s.sensor_id,
       range.*,
       min(m.min_value) as min_value,
       max(m.max_value) as max_value,
       sum(m.sum_value) as sum_value,
       coalesce(sum(m.nr_values), 0) as nr_values

from ( /* mid */
       select date_trunc(x.unit, now()) - ('1' || x.unit)::interval * (x.i-1) as starting_at,
              date_trunc(x.unit, now()) - ('1' || x.unit)::interval * (x.i-2) as ending_at
             
       from (/* inner */ select ?::text as unit, generate_series(1,?) as i) x
     ) range
     left join (values (?::integer)) s(sensor_id)
     left join measure m on (m.starting_at   >= range.starting_at
                             and m.ending_at <= range.ending_at
                             and m.sensor_id = s.sensor_id)
group by s.sensor_id, range.starting_at, range.ending_at
order by range.starting_at
});

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
