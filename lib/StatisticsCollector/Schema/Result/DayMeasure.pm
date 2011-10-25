package StatisticsCollector::Schema::Result::DayMeasure;
use DBIx::Class::Candy 
    -components => [qw(InflateColumn::DateTime)];

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

table 'virtual_day_measure';

column starting_at => {
    data_type => 'datetime', timezone => 'local',
};

column ending_at => {
    data_type => 'datetime', timezone => 'local',
};

column min_value => {
    data_type => 'int',
};

# ... need more!

# belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';

__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
select d.starting_at, d.starting_at + interval '1 day' as ending_at,
       min(m.min_value) as min_value
       /* ... */
from (select date_trunc('day', now()) - (interval '1 day') * (generate_series(1,?) - 1) as starting_at) d
     left join measure m on (m.starting_at >= d.starting_at
                         and m.ending_at   <= d.starting_at + interval '1 day'
                         and m.sensor_id   = ?)
group by d.starting_at
});

1;
