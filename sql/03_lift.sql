CREATE OR REPLACE TABLE lift_summary AS
SELECT
  treatment,
  COUNT(*)        AS n,
  SUM(visit)      AS visits,
  SUM(conversion) AS conversions,
  AVG(visit)      AS visit_rate,
  AVG(conversion) AS conv_rate
FROM uplift
GROUP BY treatment;

SELECT * FROM lift_summary ORDER BY treatment DESC;