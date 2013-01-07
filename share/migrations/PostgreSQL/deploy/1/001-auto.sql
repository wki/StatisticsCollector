-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Jan  5 18:51:21 2013
-- 
;
--
-- Table: alarm_condition.
--
CREATE TABLE "alarm_condition" (
  "alarm_condition_id" serial NOT NULL,
  "name" text,
  "sensor_mask" text NOT NULL,
  "max_measure_age_minutes" integer,
  "latest_value_gt" integer,
  "latest_value_lt" integer,
  "min_value_gt" integer,
  "max_value_lt" integer,
  "severity_level" integer DEFAULT 2 NOT NULL,
  "specificity" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("alarm_condition_id")
);

;
--
-- Table: sensor.
--
CREATE TABLE "sensor" (
  "sensor_id" serial NOT NULL,
  "name" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("sensor_id"),
  CONSTRAINT "sensor_name" UNIQUE ("name")
);

;
--
-- Table: measure.
--
CREATE TABLE "measure" (
  "measure_id" serial NOT NULL,
  "sensor_id" integer NOT NULL,
  "latest_value" integer NOT NULL,
  "min_value" integer NOT NULL,
  "max_value" integer NOT NULL,
  "sum_value" integer NOT NULL,
  "nr_values" integer NOT NULL,
  "starting_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "ending_at" timestamp NOT NULL,
  PRIMARY KEY ("measure_id")
);
CREATE INDEX "measure_idx_sensor_id" on "measure" ("sensor_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "measure" ADD CONSTRAINT "measure_fk_sensor_id" FOREIGN KEY ("sensor_id")
  REFERENCES "sensor" ("sensor_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

