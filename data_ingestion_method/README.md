The Python files used to ingest the data have been moved to the [`medicare-kpi-validation-pipeline`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline#Overview) repository.

Here is an example of one of the loader files:

- [`beneficiary_summary_loader.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/beneficiary_summary_loader.py)

This loader file shows how multithreaded batch processing was used to load the data.

Loader files used by the load scripts:

- [`beneficiary_summary_loader.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/beneficiary_summary_loader.py)
- [`carrier_claims_loader.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/carrier_claims_loader.py)
- [`outpatient_claims_loader.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/outpatient_claims_loader.py)
- [`prescript_drug_events_loader.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/prescript_drug_events_loader.py)

Load scripts called by the data pipeline orchestrator:

- [`beneficiary_summary_load.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/beneficiary_summary_load.py)
- [`carrier_claims_load.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/carrier_claims_load.py)
- [`outpatient_claims_load.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/outpatient_claims_load.py)
- [`prescript_drug_events_load.py`](https://github.com/Ryan-T-Shaffer/medicare-kpi-validation-pipeline/blob/main/src/02_data_pipeline_ingestion/prescript_drug_events_load.py)
