package StatisticsCollector::Schema::Result::AggregateMeasure;
use DBIx::Class::Candy 
    -components => [qw(InflateColumn::DateTime)];

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

table 'virtual_aggregate_measure';

column starting_at => {
    data_type => 'datetime', timezone => 'local',
};

column ending_at => {
    data_type => 'datetime', timezone => 'local',
};

column min_value => {
    data_type => 'int',
};

column min_value => {
    data_type => 'int',
    is_nullable => 0,
};

column max_value => {
    data_type => 'int',
    is_nullable => 0,
};

column sum_value => {
    data_type => 'int',
    is_nullable => 0,
};

column nr_values => {
    data_type => 'int',
    is_nullable => 0,
};


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
select range.*,
       min(m.min_value) as min_value,
       max(m.max_value) as max_value,
       sum(m.sum_value) as sum_value,
       coalesce(sum(m.nr_values), 0) as nr_values

from ( /* mid */
       select date_trunc(x.unit, now()) - ('1' || x.unit)::interval * (x.i-1) as starting_at,
              date_trunc(x.unit, now()) - ('1' || x.unit)::interval * (x.i-2) as ending_at
             
       from (/* inner */ select ?::text as unit, generate_series(1,?) as i) x
     ) range
     left join measure m on (m.starting_at   >= range.starting_at
                             and m.ending_at <= range.ending_at
                             and m.sensor_id = ?)
group by range.starting_at, range.ending_at
order by range.starting_at
});

1;
