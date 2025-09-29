/*
Copyright (c) 2025 Ryan Shaffer. All rights reserved.

File: sql/ddl/create_remaining_tables.sql
Purpose: Build a single consolidated output table (calc_dist_all) used by visuals.
         Computes three distributions and unions them:
           1) Member-months distribution (Part B, Part D, Greatest-of-two)
           2) Claims-count distribution (PROF/OP/RX)
           3) Cost-amount distribution  (PROF/OP/RX)
         Returns one table: calc_dist_all(specific_calculation, year, legend, pct).

Tested: MySQL 8.0+ (requires CTEs and window functions)

How to run:
  SOURCE sql/ddl/create_remaining_tables.sql;

Dependencies & assumptions:
  Required input tables and key columns:
    - beneficiary_summary:
        year INT,
        BENE_SMI_CVRAGE_TOT_MONS INT,   -- Part B months (0..12)
        PLAN_CVRG_MOS_NUM INT           -- Part D months (0..12)
    - carrier_claims:
        year INT, CLM_ID,
        LINE_ALOWD_CHRG_AMT_1..13 NUMERIC   -- allowed-charge columns (null-safe summed)
    - outpatient_claims:
        year INT, CLM_ID,
        CLM_PMT_AMT, NCH_BENE_PTB_DDCTBL_AMT, NCH_BENE_PTB_COINSRNC_AMT, NCH_PRMRY_PYR_CLM_PD_AMT
    - prescript_drug_events:
        year INT, TOT_RX_CST_AMT NUMERIC     -- PDE rows counted directly

  Semantics:
    - Member-month buckets are '0', '1-11', '12' based on coverage months in 0..12 range.
    - Claims_count uses DISTINCT CLM_ID for carrier/outpatient; PDE rows counted by row.
    - Cost_amount is the null-safe sum of allowed/payment fields per claims table.
  Output legends:
    - Member-months distributions use months_covered ('0','1-11','12').
    - Claims and cost distributions use svc labels: PROF (carrier), OP (outpatient), RX (PDE).

Security & portability:
  - Do NOT include credentials or local file paths in this script.
  - This script is data-warehouse-safe and portable across environments with the tables above.

Style conventions:
  - SQL keywords in UPPERCASE; identifiers in snake_case.
  - Clear table aliases (e.g., bs, cc, op, pde); 2-space indentation.
  - One clause per line for long statements; trailing commas aligned.

Performance expectations (brief):
  - Recommend BTREE indexes on joins/filters: (year), (CLM_ID, year) on claims tables.
  - Partitioning claims tables by month/year improves scan times.
  - With proper indexing/partitioning, expect minutes to tens of minutes on developer hardware.
  - Use EXPLAIN / EXPLAIN ANALYZE to verify partition pruning and index usage.

Last updated: 2025-09-28
*/
DROP TABLE IF EXISTS calc_dist_all;

CREATE TABLE calc_dist_all AS
WITH
/* -----------------------------
   1) Member-months distributions
   ----------------------------- */
cte_mm_b AS (
  SELECT
      bs.`year`,
      CASE
        WHEN bs.BENE_SMI_CVRAGE_TOT_MONS = 0  THEN '0'
        WHEN bs.BENE_SMI_CVRAGE_TOT_MONS = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY bs.`year`), 2) AS pct
  FROM beneficiary_summary AS bs
  WHERE bs.BENE_SMI_CVRAGE_TOT_MONS BETWEEN 0 AND 12
  GROUP BY bs.`year`, months_covered
),
cte_mm_d AS (
  SELECT
      bs.`year`,
      CASE
        WHEN bs.PLAN_CVRG_MOS_NUM = 0  THEN '0'
        WHEN bs.PLAN_CVRG_MOS_NUM = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY bs.`year`), 2) AS pct
  FROM beneficiary_summary AS bs
  WHERE bs.PLAN_CVRG_MOS_NUM BETWEEN 0 AND 12
  GROUP BY bs.`year`, months_covered
),
cte_mm_greatest AS (
  SELECT
      y.`year`,
      CASE
        WHEN y.months_max = 0  THEN '0'
        WHEN y.months_max = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY y.`year`), 2) AS pct
  FROM (
      SELECT bs.`year`,
             GREATEST(bs.BENE_SMI_CVRAGE_TOT_MONS, bs.PLAN_CVRG_MOS_NUM) AS months_max
      FROM beneficiary_summary AS bs
  ) AS y
  GROUP BY y.`year`, months_covered
),

/* -----------------------------
   2) Claims-count distribution
   ----------------------------- */
cte_claims_counts AS (
  SELECT `year`, 'PROF' AS svc, COUNT(DISTINCT CLM_ID) AS claims_count
  FROM carrier_claims
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'OP'   AS svc, COUNT(DISTINCT CLM_ID) AS claims_count
  FROM outpatient_claims
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'RX'   AS svc, COUNT(*) AS claims_count  -- PDE_ID unique
  FROM prescript_drug_events
  GROUP BY `year`
),
cte_claims AS (
  SELECT
      c.`year`,
      c.svc AS legend,  -- standardized labels: PROF/OP/RX
      ROUND(100 * c.claims_count / SUM(c.claims_count) OVER (PARTITION BY c.`year`), 2) AS pct
  FROM cte_claims_counts AS c
),

/* -----------------------------
   3) Cost-amount distribution
   ----------------------------- */
cte_cost_amounts AS (
  SELECT
      `year`,
      'PROF' AS svc,
      SUM(  COALESCE(LINE_ALOWD_CHRG_AMT_1 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_2 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_3 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_4 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_5 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_6 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_7 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_8 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_9 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_10,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_11,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_12,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_13,0)
      ) AS cost_amount
  FROM carrier_claims
  GROUP BY `year`
  UNION ALL
  SELECT
      `year`,
      'OP' AS svc,
      SUM(  COALESCE(CLM_PMT_AMT               ,0)
          + COALESCE(NCH_BENE_PTB_DDCTBL_AMT   ,0)
          + COALESCE(NCH_BENE_PTB_COINSRNC_AMT ,0)
          + COALESCE(NCH_PRMRY_PYR_CLM_PD_AMT  ,0)
      ) AS cost_amount
  FROM outpatient_claims
  GROUP BY `year`
  UNION ALL
  SELECT
      `year`,
      'RX' AS svc,
      SUM(COALESCE(TOT_RX_CST_AMT,0)) AS cost_amount
  FROM prescript_drug_events
  GROUP BY `year`
),
cte_cost AS (
  SELECT
      a.`year`,
      a.svc AS legend,  -- standardized labels: PROF/OP/RX
      ROUND(100 * a.cost_amount / SUM(a.cost_amount) OVER (PARTITION BY a.`year`), 2) AS pct
  FROM cte_cost_amounts AS a
)

/* -----------------------------
   4) Final union of three distributions
   ----------------------------- */
SELECT
  'part_b' AS specific_calculation,
  b.`year`,
  b.months_covered AS legend,
  b.pct
FROM cte_mm_b AS b

UNION ALL
SELECT
  'part_d' AS specific_calculation,
  d.`year`,
  d.months_covered AS legend,
  d.pct
FROM cte_mm_d AS d

UNION ALL
SELECT
  'greatest_amt_months' AS specific_calculation,
  g.`year`,
  g.months_covered AS legend,
  g.pct
FROM cte_mm_greatest AS g

UNION ALL
SELECT
  'claims_dist' AS specific_calculation,
  cc.`year`,
  cc.legend,
  cc.pct
FROM cte_claims AS cc

UNION ALL
SELECT
  'cost_dist' AS specific_calculation,
  co.`year`,
  co.legend,
  co.pct
FROM cte_cost AS co
;
