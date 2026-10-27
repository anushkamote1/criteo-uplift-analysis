-- 01_load.sql
-- Loads the Criteo Uplift v2.1 dataset (13,979,592 rows) into Snowflake.
-- File is uploaded to the stage separately with:
--   snow stage copy data/criteo-research-uplift-v2.1.csv.gz @criteo.public.criteo_stage

-- Setup
CREATE WAREHOUSE IF NOT EXISTS uplift_wh
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
USE WAREHOUSE uplift_wh;

CREATE DATABASE IF NOT EXISTS criteo;
USE SCHEMA criteo.public;

CREATE FILE FORMAT IF NOT EXISTS csv_gz
  TYPE = CSV SKIP_HEADER = 1 COMPRESSION = GZIP;

CREATE STAGE IF NOT EXISTS criteo_stage FILE_FORMAT = csv_gz;

CREATE TABLE IF NOT EXISTS uplift_raw (
  f0 FLOAT, f1 FLOAT, f2 FLOAT, f3 FLOAT, f4 FLOAT, f5 FLOAT,
  f6 FLOAT, f7 FLOAT, f8 FLOAT, f9 FLOAT, f10 FLOAT, f11 FLOAT,
  treatment INT, conversion INT, visit INT, exposure INT
);

-- Load
LIST @criteo_stage;
COPY INTO uplift_raw FROM @criteo_stage;

-- Sanity checks
SELECT COUNT(*) FROM uplift_raw;

SELECT
  AVG(treatment)  AS treat_share,
  AVG(visit)      AS visit_rate,
  AVG(conversion) AS conv_rate,
  AVG(exposure)   AS exposure_rate
FROM uplift_raw;

-- Working table with a user id
CREATE OR REPLACE TABLE uplift AS
SELECT SEQ8() AS user_id, * FROM uplift_raw;

SELECT COUNT(*), COUNT(DISTINCT user_id) FROM uplift;