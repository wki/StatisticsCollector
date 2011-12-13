/* just a collection of dummy sql statements */

-- grouping in a subselect
select ...

from sensor s
     join 

where s.sensor_id in (1,2,3,4,5)
;


/* try to use a window function
   the window function per se does not shrink the nr of rows
   but allows this in an outer query
*/
select x.*
from (select s.sensor_id, s.name,
             ac.alarm_condition_id, ac.sensor_mask, ac.specificity, ac.severity_level,
             first_value(ac.alarm_condition_id) over w best_alarm_condition_id,
             first_value(sensor_mask) over w
      from sensor s 
           join alarm_condition ac on (s.name like ac.sensor_mask)
      where s.sensor_id in (1,2,3,4,5)
      window w as (partition by s.sensor_id, ac.severity_level 
                   order by ac.severity_level desc, ac.specificity desc)
) x
where x.alarm_condition_id = x.best_alarm_condition_id
;


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
                                     and age(now(), m.updated_at) > (interval '1 minute') * ac.max_measure_age_minutes
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
                     -- left join alarm_condition ac on (s.name like ac.sensor_mask)
                     left join (select x.*
                                from (select s.sensor_id,
                                             ac.*,
                                             first_value(ac.alarm_condition_id) over w best_alarm_condition_id
                                      from sensor s 
                                           join alarm_condition ac on (s.name like ac.sensor_mask)
                                      window w as (partition by s.sensor_id, ac.severity_level 
                                                   order by ac.severity_level desc, ac.specificity desc)
                                     ) x
                                where x.alarm_condition_id = x.best_alarm_condition_id
                               ) ac on ac.sensor_id = s.sensor_id
                group by m.measure_id
               ) m on (sm.latest_measure_id = m.measure_id)
where sm.sensor_id in (26,27)
;



-- update from version 1 to 2

alter table sensor 
    add column active boolean not null default true, 
    add column default_graph_type text not null default 'avg';

update sensor set default_graph_type ='sum' where name like '%/renderer/%';


