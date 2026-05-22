The queries used to aggregate the data have been moved to the [`medicare-kpi-validation-pipeline`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline#Overview) repository.

More specifically, the main KPI aggregations can be found here:

- [`Main KPI Aggregation Query`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/05_kpi_calc_sql/kpi_calc_query.sql#L87-L276)

Additional supporting KPI aggregations can be found here:

- [`Other KPI Queries`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/05_kpi_calc_sql/other_calc_queries.sql#L85-L335)

The DDL for the Medicare tables used by these KPI queries can be found here:

- [`Medicare Table DDL`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/tree/main/src/01_sql_schema_build)
