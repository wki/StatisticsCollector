-- Convert schema '/Users/wolfgang/proj/StatisticsCollector/script/../share/migrations/_source/deploy/1/001-auto.yml' to '/Users/wolfgang/proj/StatisticsCollector/script/../share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "alarm" (
  "alarm_id" serial NOT NULL,
  "alarm_condition_id" integer NOT NULL,
  "sensor_id" integer NOT NULL,
  "starting_at" timestamp NOT NULL,
  "last_notified_at" timestamp,
  "ending_at" timestamp,
  PRIMARY KEY ("alarm_id")
);
CREATE INDEX "alarm_idx_alarm_condition_id" on "alarm" ("alarm_condition_id");
CREATE INDEX "alarm_idx_sensor_id" on "alarm" ("sensor_id");

;
CREATE TABLE "alarm_kind" (
  "alarm_kind_id" serial NOT NULL,
  "name" text,
  "kind" text,
  "destination" text,
  "arg1" text,
  "arg2" text,
  PRIMARY KEY ("alarm_kind_id")
);

insert into alarm_kind (alarm_kind_id, name, kind, destination)
    values (1, 'Mail', 'Mail', 'wolfgang@kinkeldei.de'),
           (2, 'SMS',  'SMS',  '491729078944');

alter sequence alarm_kind_alarm_kind_id_seq restart with 3;

;
ALTER TABLE "alarm" ADD CONSTRAINT "alarm_fk_alarm_condition_id" FOREIGN KEY ("alarm_condition_id")
  REFERENCES "alarm_condition" ("alarm_condition_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "alarm" ADD CONSTRAINT "alarm_fk_sensor_id" FOREIGN KEY ("sensor_id")
  REFERENCES "sensor" ("sensor_id") DEFERRABLE;

;
ALTER TABLE alarm_condition ADD COLUMN alarm_kind_id integer NOT NULL default 1;

;
ALTER TABLE sensor ADD COLUMN active boolean DEFAULT '1' NOT NULL;

;
ALTER TABLE sensor ADD COLUMN default_graph_type text DEFAULT 'avg' NOT NULL;

;
CREATE INDEX alarm_condition_idx_alarm_kind_id on alarm_condition (alarm_kind_id);

;
ALTER TABLE alarm_condition ADD CONSTRAINT alarm_condition_fk_alarm_kind_id FOREIGN KEY (alarm_kind_id)
  REFERENCES alarm_kind (alarm_kind_id) DEFERRABLE;

;

COMMIT;

