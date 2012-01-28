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

column max_severity_level => {
    data_type => 'int',
};

belongs_to sensor => 'StatisticsCollector::Schema::Result::Sensor', 'sensor_id';

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{
    select m.*,
           case when ac.max_measure_age_minutes is not null
                     and age(now(), m.updated_at) > (interval '1 minute') * ac.max_measure_age_minutes
                    then 1
                    else 0 end > 0 as measure_age_alarm,
           
           case when ac.latest_value_gt is not null
                     and m.latest_value <= ac.latest_value_gt
                    then 1
                    else 0 end > 0 as latest_value_gt_alarm,
           case when ac.latest_value_lt is not null
                     and m.latest_value >= ac.latest_value_lt
                    then 1
                    else 0 end > 0 as latest_value_lt_alarm,
           
           case when ac.min_value_gt is not null
                     and m.min_value <= ac.min_value_gt
                    then 1
                    else 0 end > 0 as min_value_gt_alarm,
           case when ac.max_value_lt is not null
                     and m.max_value >= ac.max_value_lt
                    then 1
                    else 0 end > 0 as max_value_lt_alarm,
           
           case when (ac.max_measure_age_minutes is not null
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
                    else null end as max_severity_level
           
    from (select sensor_id, max(measure_id) as latest_measure_id
          from measure
          group by sensor_id) sm
         left join measure m on m.measure_id = sm.latest_measure_id
         left join (select x.*
                    from (select s.sensor_id,
                                 ac1.*,
                                 first_value(ac1.alarm_condition_id) over w best_alarm_condition_id
                          from sensor s 
                               join alarm_condition ac1 on (s.name like ac1.sensor_mask)
                          window w as (partition by s.sensor_id /*, ac1.severity_level */
                                       order by ac1.severity_level desc, ac1.specificity desc)
                         ) x
                    where x.alarm_condition_id = x.best_alarm_condition_id
                   ) ac on ac.sensor_id = m.sensor_id
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
