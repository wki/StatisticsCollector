package StatisticsCollector::Schema::Result::LatestMeasure;
use DBIx::Class::Candy 
    -components => [qw(InflateColumn::DateTime)],
    -base => 'StatisticsCollector::Schema::Result::Measure';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

table 'virtual_latest_measure';

# columns defined in base class, except:

column measure_age_alarm => {
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
                           -- we only have one measure, but it looks better to use the proper aggregates
                           min(m.min_value)   as min_value,
                           max(m.max_value)   as max_value,
                           sum(m.sum_value)   as sum_value,
                           sum(m.nr_values)   as nr_values,
                           min(m.starting_at) as starting_at,
                           max(m.ending_at)   as ending_at,
                           
                           -- aggregate alarm conditions
                           sum(case when ac.max_measure_age is not null
                                         and age(m.starting_at, now()) > (interval '1 hour') * ac.max_measure_age
                                        then 1
                                        else 0 end) > 0 as measure_age_alarm,
                           sum(case when ac.min_value_gt is not null
                                         and m.min_value > ac.min_value_gt
                                        then 1
                                        else 0 end) > 0 as min_value_gt_alarm,
                           sum(case when ac.max_value_lt is not null
                                         and m.max_value < ac.max_value_lt
                                        then 1
                                        else 0 end) > 0 as max_value_lt_alarm,
                           max(case when (ac.max_measure_age is not null
                                          and age(m.starting_at, now()) > (interval '1 hour') * ac.max_measure_age)
                                      or (ac.min_value_gt is not null
                                          and m.min_value > ac.min_value_gt)
                                      or (ac.max_value_lt is not null
                                         and m.max_value < ac.max_value_lt)
                                        then ac.severity_level
                                        else null end) as max_severity_level,
                           count(distinct ac.alarm_condition_id) as nr_matching_alarm_conditions
                    from measure m
                         join sensor s on (m.sensor_id = s.sensor_id)
                         left join alarm_condition ac on (s.name like ac.sensor_mask)
                    group by m.measure_id
                    /*
                        TODO: do we need a prio? 
                        TODO: is one alarm more important than an other?
                    order by m.measure_id, ac.severity_level desc
                    */
                   ) m on (sm.latest_measure_id = m.measure_id)
});

sub has_alarm {
    my $self = shift;
    
    return $self->measure_age_alarm || $self->min_value_gt_alarm || $self->max_value_lt_alarm
      ? 1
      : 0;
}
1;
