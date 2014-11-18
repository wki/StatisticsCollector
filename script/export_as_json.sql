\pset format unaligned
\pset tuples_only

\o sensor.json

select '[' || string_agg(j::text, E',\n') || ']' 
from (select row_to_json(row) j 
      from (select * from sensor) row
     ) line;

\o measure.json

select '[' || string_agg(j::text, E',\n') || ']' 
from (select row_to_json(row) j 
      from (select * from measure order by starting_at) row
     ) line;

\o
\pset format aligned
