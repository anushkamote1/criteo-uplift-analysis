SELECT
  COUNT(*)                                        AS n,
  COUNT_IF(treatment NOT IN (0,1))                AS bad_treatment,
  COUNT_IF(visit NOT IN (0,1))                    AS bad_visit,
  COUNT_IF(conversion NOT IN (0,1))               AS bad_conversion,
  COUNT_IF(exposure NOT IN (0,1))                 AS bad_exposure,
  COUNT_IF(conversion = 1 AND visit = 0)          AS convert_without_visit,
  COUNT_IF(exposure = 1 AND treatment = 0)        AS exposed_control,
  COUNT_IF(f0 IS NULL OR f1 IS NULL OR f2 IS NULL OR f3 IS NULL
        OR f4 IS NULL OR f5 IS NULL OR f6 IS NULL OR f7 IS NULL
        OR f8 IS NULL OR f9 IS NULL OR f10 IS NULL OR f11 IS NULL) AS rows_with_nulls
FROM uplift;

WITH obs AS (
  SELECT COUNT(*) AS n,
         SUM(treatment) AS n_t,
         COUNT(*) - SUM(treatment) AS n_c
  FROM uplift
)
SELECT
  n, n_t, n_c,
  n_t / n AS treat_share,
  POWER(n_t - 0.85*n, 2) / (0.85*n)
    + POWER(n_c - 0.15*n, 2) / (0.15*n) AS chi_sq
FROM obs;

WITH long AS (
  SELECT treatment, feature, value
  FROM uplift
  UNPIVOT (value FOR feature IN (f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11))
),
stats AS (
  SELECT feature, treatment, AVG(value) AS m, VARIANCE(value) AS v
  FROM long
  GROUP BY feature, treatment
)
SELECT
  t.feature,
  t.m AS mean_treatment,
  c.m AS mean_control,
  (t.m - c.m) / SQRT((t.v + c.v) / 2) AS smd
FROM stats t
JOIN stats c
  ON t.feature = c.feature AND t.treatment = 1 AND c.treatment = 0
ORDER BY ABS(smd) DESC;