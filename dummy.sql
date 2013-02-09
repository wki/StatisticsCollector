/* just a collection of dummy sql statements */

-- grouping in a subselect
select ...

from sensor s
     join 

where s.sensor_id in (1,2,3,4,5)
;

/* better join plan

    all of
    (
        columns: m.*, 
                 s.*, 
                 tested alarm conditions, 
                 firing
        latest (measure_id, sensor_id)       s
        --> measure                          s
        --> (sensors and matching ac)        s * severity
    )
    windowed on s.id
             ordered by: firing desc, severity desc
*/





/* 
   sensors and all matching alarm conditions, the best specific for every severity
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
where sm.sensor_id in (1,2,3,4,5)
;



-- update from version 1 to 2

alter table sensor 
    add column active boolean not null default true, 
    add column default_graph_type text not null default 'avg';

update sensor set default_graph_type ='sum' where name like '%/renderer/%';


-- speedup for querying many measures
create index measure_sensor on measure (sensor_id);
create index measure_starting_at on measure (starting_at);
create index measure_ending_at on measure (ending_at);

-- this change improves a lot on 9.2 but not on 9.1...
explain analyze
select m.sensor_id,
       range.*,
       min(m.min_value) as min_value,
       max(m.max_value) as max_value,
       sum(m.sum_value) as sum_value,
       coalesce(sum(m.nr_values), 0) as nr_values

from ( /* range: starting_at, ending_at */
       select date_trunc(u.unit, now()) - ('1' || u.unit)::interval * (u.i-1) as starting_at,
              date_trunc(u.unit, now()) - ('1' || u.unit)::interval * (u.i-2) as ending_at
             
       from (
           /* u: unit, i */ 
           select 'month'::text as unit, generate_series(1,20)::integer as i
           /* values ('month'::text,  1::integer),
                  ('month'::text,  2::integer),
                  ('month'::text,  3::integer),
                  ('month'::text,  4::integer),
                  ('month'::text,  5::integer),
                  ('month'::text,  6::integer),
                  ('month'::text,  7::integer),
                  ('month'::text,  8::integer),
                  ('month'::text,  9::integer),
                  ('month'::text, 10::integer),
                  ('month'::text, 11::integer),
                  ('month'::text, 12::integer),
                  ('month'::text, 13::integer),
                  ('month'::text, 14::integer),
                  ('month'::text, 15::integer),
                  ('month'::text, 16::integer),
                  ('month'::text, 17::integer),
                  ('month'::text, 18::integer),
                  ('month'::text, 19::integer),
                  ('month'::text, 20::integer) */
       ) u(unit, i)
     ) range
     left join measure m on (m.starting_at   >= range.starting_at
                             and m.ending_at <= range.ending_at
                             and m.sensor_id = 26)
group by m.sensor_id, range.starting_at, range.ending_at
order by range.starting_at
;


