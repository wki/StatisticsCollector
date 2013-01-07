-- Convert schema '/Users/wolfgang/proj/StatisticsCollector/script/../share/migrations/_source/deploy/2/001-auto.yml' to '/Users/wolfgang/proj/StatisticsCollector/script/../share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alarm_condition DROP CONSTRAINT alarm_condition_fk_alarm_kind_id;

;
DROP INDEX alarm_condition_idx_alarm_kind_id;

;
ALTER TABLE alarm_condition DROP COLUMN alarm_kind_id;

;
ALTER TABLE sensor DROP COLUMN active;

;
ALTER TABLE sensor DROP COLUMN default_graph_type;

;
DROP TABLE alarm_kind CASCADE;

;
DROP TABLE alarm CASCADE;

;

COMMIT;

