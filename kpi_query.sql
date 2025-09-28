/* 
File: sql/kpi_query.sql
Purpose: Compute KPI rollups (Cost PMPM, Count PMPM, MLR) by year (2008-2010), svc (Total/RX/PROF/OP), 
and race_group (AB, Black, Caucasian, Hispanic, Other).

Tested: MySQL 8.0+
How to run:  SOURCE sql/kpi_query.sql;

Inputs (tables):
  - beneficiaries            (DESYNPUF_ID, year, race_group or BENE_RACE_CD, member_months fields)
  - claims_prof / claims_op / claims_rx (allowed_cost, dates, DESYNPUF_ID)
  - premium reference tables (optional: monthly rates by year)

Output:
  - kpi_year_final (year, svc, svc_group, race_group, cost_pmpm, cnt_pmpm, mlr_pct)

Last updated: 2025-09-28
*/

CREATE TABLE kpi_year_final
ENGINE = InnoDB
AS
WITH
/* 1) Per-table, per-member, per-year subtotals (same patterns as your originals) */
pde AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(COALESCE(TOT_RX_CST_AMT,0)) AS cost_pde,
         COUNT(PDE_ID)                   AS cnt_pde
  FROM prescript_drug_events
  GROUP BY DESYNPUF_ID, `year`
),
carrier AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(
           COALESCE(LINE_ALOWD_CHRG_AMT_1 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_2 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_3 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_4 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_5 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_6 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_7 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_8 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_9 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_10,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_11,0) + COALESCE(LINE_ALOWD_CHRG_AMT_12,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_13,0)
         ) AS cost_carrier,
         COUNT(DISTINCT CLM_ID) AS cnt_carrier
  FROM carrier_claims
  GROUP BY DESYNPUF_ID, `year`
),
outp AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(
           COALESCE(CLM_PMT_AMT              ,0) +
           COALESCE(NCH_BENE_PTB_DDCTBL_AMT  ,0) +
           COALESCE(NCH_BENE_PTB_COINSRNC_AMT,0) +
           COALESCE(NCH_PRMRY_PYR_CLM_PD_AMT ,0)
         ) AS cost_outp,
         COUNT(DISTINCT CLM_ID) AS cnt_outp
  FROM outpatient_claims
  GROUP BY DESYNPUF_ID, `year`
),

/* 2) Member-year rollup (keep race and both denominators & premiums) */
member_year AS (
  SELECT
    bs.DESYNPUF_ID,
    bs.`year`,
    bs.BENE_RACE_CD,
    COALESCE(bs.BENE_SMI_CVRAGE_TOT_MONS,0) AS mm_pt_b,
    COALESCE(bs.PLAN_CVRG_MOS_NUM      ,0) AS mm_pt_d,
    pb.monthly_rate * COALESCE(bs.BENE_SMI_CVRAGE_TOT_MONS,0) AS prem_b,
    pd.monthly_rate * COALESCE(bs.PLAN_CVRG_MOS_NUM      ,0) AS prem_d,
    COALESCE(pde.cost_pde     ,0) AS cost_pde,
    COALESCE(carrier.cost_carrier,0) AS cost_carrier,
    COALESCE(outp.cost_outp   ,0) AS cost_outp,
    COALESCE(pde.cnt_pde      ,0) AS cnt_pde,
    COALESCE(carrier.cnt_carrier ,0) AS cnt_carrier,
    COALESCE(outp.cnt_outp    ,0) AS cnt_outp,
    /* totals for 'Total' svc */
    COALESCE(pde.cost_pde     ,0) +
    COALESCE(carrier.cost_carrier,0) +
    COALESCE(outp.cost_outp   ,0) AS total_allowed_cost,
    COALESCE(pde.cnt_pde      ,0) +
    COALESCE(carrier.cnt_carrier ,0) +
    COALESCE(outp.cnt_outp    ,0) AS total_claim_count
  FROM beneficiary_summary bs
  LEFT JOIN pde     USING (DESYNPUF_ID, `year`)
  LEFT JOIN carrier USING (DESYNPUF_ID, `year`)
  LEFT JOIN outp    USING (DESYNPUF_ID, `year`)
  LEFT JOIN z_part_b_premium_cost pb USING (`year`)
  LEFT JOIN z_part_d_premium_cost pd USING (`year`)
),

/* 3) Denominators/premiums by race + an AB rollup (Σ over all races) */
denoms AS (
  /* AB: sum across all races */
  SELECT
    `year`,
    'AB' AS race_group,
    SUM(mm_pt_b)                            AS mm_b,
    SUM(mm_pt_d)                            AS mm_d,
    SUM(GREATEST(mm_pt_b, mm_pt_d))         AS mm_all,
    SUM(prem_b)                             AS prem_b,
    SUM(prem_d)                             AS prem_d,
    SUM(prem_b + prem_d)                    AS prem_all
  FROM member_year
  GROUP BY `year`
  UNION ALL
  /* Each race group */
  SELECT
    `year`,
    CASE BENE_RACE_CD
      WHEN 1 THEN 'Caucasian'
      WHEN 2 THEN 'Black'
      WHEN 3 THEN 'Other'
      WHEN 4 THEN 'Asian'
      WHEN 5 THEN 'Hispanic'
      WHEN 6 THEN 'Native American'
      ELSE 'Unknown'
    END AS race_group,
    SUM(mm_pt_b)                            AS mm_b,
    SUM(mm_pt_d)                            AS mm_d,
    SUM(GREATEST(mm_pt_b, mm_pt_d))         AS mm_all,
    SUM(prem_b)                             AS prem_b,
    SUM(prem_d)                             AS prem_d,
    SUM(prem_b + prem_d)                    AS prem_all
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
),

/* 4) Service-line numerators (allowed & count) by race + AB rollup */
svc AS (
  /* AB (all beneficiaries) */
  SELECT `year`, 'AB' AS race_group, 'ALL' AS svc,
         SUM(total_allowed_cost) AS allowed, SUM(total_claim_count) AS cnt
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'PROF', SUM(cost_carrier), SUM(cnt_carrier)
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'RX',   SUM(cost_pde),     SUM(cnt_pde)
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'OP',   SUM(cost_outp),    SUM(cnt_outp)
  FROM member_year
  GROUP BY `year`

  UNION ALL

  /* Each race group */
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'ALL' AS svc,
         SUM(total_allowed_cost), SUM(total_claim_count)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'PROF' AS svc,
         SUM(cost_carrier), SUM(cnt_carrier)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'RX' AS svc,
         SUM(cost_pde), SUM(cnt_pde)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'OP' AS svc,
         SUM(cost_outp), SUM(cnt_outp)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
)

/* 5) Final rollup: pick denominators by svc and compute KPIs */
SELECT
  s.`year`,
  CASE WHEN s.svc = 'ALL' THEN 'Total' ELSE s.svc END AS svc,
  CASE WHEN s.svc = 'ALL' THEN 'Total' ELSE 'Service Line' END AS svc_group,
  s.race_group,

  /* Cost PMPM = Σ Allowed / Σ Member Months (svc-specific denominator) */
  ROUND(
    s.allowed /
    CASE
      WHEN s.svc = 'ALL' THEN d.mm_all      /* Total uses max(B,D) per member */
      WHEN s.svc = 'RX'  THEN d.mm_d        /* RX on Part D months           */
      ELSE                   d.mm_b         /* OP/PROF on Part B months      */
    END, 2
  ) AS cost_pmpm,

  /* Count PMPM = Σ Claim Count / Σ Member Months */
  ROUND(
    s.cnt /
    CASE
      WHEN s.svc = 'ALL' THEN d.mm_all
      WHEN s.svc = 'RX'  THEN d.mm_d
      ELSE                   d.mm_b
    END, 2
  ) AS cnt_pmpm,

  /* MLR (%) = Σ Allowed / Σ Premium Revenue * 100 */
  ROUND(
    (s.allowed /
     CASE
       WHEN s.svc = 'ALL' THEN d.prem_all
       WHEN s.svc = 'RX'  THEN d.prem_d
       ELSE                  d.prem_b
     END) * 100, 2
  ) AS mlr_pct

FROM svc s
JOIN denoms d
  ON d.`year` = s.`year`
 AND d.race_group = s.race_group
ORDER BY s.`year`, svc, s.race_group;

ALTER TABLE kpi_year_final
  ADD PRIMARY KEY (`year`, svc, race_group);
