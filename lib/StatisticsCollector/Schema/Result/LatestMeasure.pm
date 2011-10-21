package StatisticsCollector::Schema::Result::LatestMeasure;
use DBIx::Class::Candy 
    # -components => [qw(InflateColumn::DateTime)],
    -base => 'StatisticsCollector::Schema::Result::Measure';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

table 'virtual_latest_measure';

# all columns defined in base class, plus:

column measure_age_alarm => {
    data_type => 'boolean',
};

column latest_value_gt_alarm => {
    data_type => 'boolean',
};

column latest_value_lt_alarm => {
    data_type => 'boolean',
};

column min_value_gt_alarm => {
    data_type => 'boolean',
};

column max_value_lt_alarm => {
    data_type => 'boolean',
};

column nr_matching_alarm_conditions => {
    data_type => 'int',
};

column max_severity_level => {
    data_type => 'int',
};

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';

__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
    select sm.sensor_id,
           m.*
    from (select sensor_id, max(measure_id) as latest_measure_id
          from measure
          group by sensor_id) sm
         left join (select m.measure_id,
                           /* use of aggregate functions needed here */
                           min(distinct m.latest_value) as latest_value,
                           min(distinct m.min_value)    as min_value,
                           max(distinct m.max_value)    as max_value,
                           min(distinct m.sum_value)    as sum_value,
                           max(distinct m.nr_values)    as nr_values,
                           min(distinct m.starting_at)  as starting_at,
                           max(distinct m.updated_at)   as updated_at,
                           max(distinct m.ending_at)    as ending_at,
                           
                           /* aggregate alarm conditions */
                           sum(case when ac.max_measure_age_minutes is not null
                                         and age(now(), m.starting_at) > (interval '1 minute') * ac.max_measure_age_minutes
                                        then 1
                                        else 0 end) > 0 as measure_age_alarm,
                           
                           sum(case when ac.latest_value_gt is not null
                                         and m.latest_value <= ac.latest_value_gt
                                        then 1
                                        else 0 end) > 0 as latest_value_gt_alarm,
                           sum(case when ac.latest_value_lt is not null
                                         and m.latest_value >= ac.latest_value_lt
                                        then 1
                                        else 0 end) > 0 as latest_value_lt_alarm,
                           
                           sum(case when ac.min_value_gt is not null
                                         and m.min_value <= ac.min_value_gt
                                        then 1
                                        else 0 end) > 0 as min_value_gt_alarm,
                           sum(case when ac.max_value_lt is not null
                                         and m.max_value >= ac.max_value_lt
                                        then 1
                                        else 0 end) > 0 as max_value_lt_alarm,
                           
                           max(case when (ac.max_measure_age_minutes is not null
                                          and age(now(), m.updated_at) > (interval '1 minute') * ac.max_measure_age_minutes)
                                      or (ac.latest_value_gt is not null
                                          and m.latest_value <= ac.latest_value_gt)
                                      or (ac.latest_value_lt is not null
                                         and m.latest_value >= ac.latest_value_lt)
                                      or (ac.min_value_gt is not null
                                          and m.min_value <= ac.min_value_gt)
                                      or (ac.max_value_lt is not null
                                         and m.max_value >= ac.max_value_lt)
                                        then ac.severity_level
                                        else null end) as max_severity_level,
                           count(distinct ac.alarm_condition_id) as nr_matching_alarm_conditions
                    from measure m
                         join sensor s on (m.sensor_id = s.sensor_id)
                         left join alarm_condition ac on (s.name like ac.sensor_mask)
                    group by m.measure_id
                   ) m on (sm.latest_measure_id = m.measure_id)
});

sub has_alarm {
    my $self = shift;
    
    return $self->measure_age_alarm ||
           $self->latest_value_gt_alarm || $self->latest_value_lt_alarm ||
           $self->min_value_gt_alarm || $self->max_value_lt_alarm
      ? 1
      : 0;
}
1;
