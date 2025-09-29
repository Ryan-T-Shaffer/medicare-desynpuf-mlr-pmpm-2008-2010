
# -*- coding: utf-8 -*-
"""
© 2025 Ryan Shaffer. All rights reserved.
SAMPLE INGESTION MODULE — The complete, production ETL/DDL codebase for writing
this database to MySQL will be published soon in a separate repository.

Title
-----
Parallel CSV → MySQL loader (Classic Protocol) for `carrier_claims`

Purpose
-------
Provide a focused, shell-friendly function that bulk-loads a folder of CSV files
into a target MySQL schema.table using MySQL Shell's Python API (`util.import_table`).

Dependencies & Assumptions (what and why)
-----------------------------------------
- MySQL Shell 8.0/8.4, running in **Classic Protocol** (TCP 3306) with an active
  `__main__.session` and `__main__.util` available. This function is intended to be
  executed *inside* `mysqlsh --py` so we don't create or manage connections here.
- Server must permit LOCAL INFILE (e.g., `local_infile=ON`). Classic protocol is
  required for LOCAL file imports; X Protocol does not support it.
- Column mapping is explicit via `columns` and `decodeColumns` so empty strings are
  normalized to SQL NULL (using `NULLIF(TRIM(@n), '')`) for robust downstream SQL.
- Credentials and machine-specific paths are **not** embedded here. Pass inputs from
  a separate caller (see companion call script) and/or environment variables.

Keep Credentials & Local Paths Out
----------------------------------
- No usernames, passwords, or absolute paths are hard-coded. The caller provides
  `folder`, `schema`, `table`, and `threads`. This module focuses solely on the
  import mechanics and column decoding.

Consistent Style (what that means here)
---------------------------------------
- PEP 8 naming and type hints for public functions.
- Logging (INFO level by default) instead of print statements for consistent output.
- Immutable inputs (no in-place mutation of user-supplied arguments).
- f-strings for formatting, pathlib for readable file names.

Performance Expectations (brief)
--------------------------------
- Throughput depends on disk and CPU. NVMe + adequate threads generally outperforms
  HDD/USB media. Expect aggregate MB/s to scale sub-linearly with threads.
- Larger CSVs benefit from higher `threads`, but contention (I/O, CPU, locks) and
  single-file imports can cap scaling. Tune `threads` empirically (e.g., 4–12).
- Use `SHOW WARNINGS` to identify decode or row issues; see summary below.

Copyright
---------
This sample is copyright-protected and provided for demonstration only.
"""
from __main__ import session, util  # provided by mysqlsh --py
import logging
import os
import glob
from pathlib import Path
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)
if not logger.handlers:
    # Defer final level/handlers to the caller; provide a sane default.
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def load_csv_folder_classic_protocol(
    *,
    folder: str,
    schema: str,
    table: str,
    threads: int,
    pattern: str = "*.csv",
) -> None:
    """
    Bulk-import all CSV files in `folder` matching `pattern` into `schema.table`
    using MySQL Shell's Classic Protocol `util.import_table`.

    Parameters
    ----------
    folder : str
        Absolute or relative folder path containing input CSV files.
    schema : str
        Target MySQL schema name.
    table : str
        Target MySQL table name.
    threads : int
        Degree of parallelism for `util.import_table` (try 4–12).
    pattern : str, default "*.csv"
        Glob pattern for selecting CSV files in `folder`.

    Notes
    -----
    - Expects to run under `mysqlsh --py` with an active Classic Protocol session.
    - Normalizes empty strings → NULL via `decodeColumns` mapping.
    - Does NOT manage connections or credentials by design.
    """
    # 1) Resolve and enumerate files
    abs_folder = os.path.abspath(folder)
    files: List[str] = glob.glob(os.path.join(abs_folder, pattern))
    if not files:
        logger.warning("No CSV files found under %s (pattern=%s)", abs_folder, pattern)
        return

    logger.info("Files to load (pattern=%s):", pattern)
    for f in files:
        logger.info("  • %s", Path(f).name)
    logger.info("Total files: %d", len(files))

    # 2) Wildcard import path for util.import_table
    wildcard = os.path.join(abs_folder, pattern).replace("\\", "/").replace("\\", "/").replace("\\", "/").replace("\", "/")

    # 3) Column ordinals and decode expressions (sample layout for carrier_claims)
    #    Replace with exact schema-specific mapping as appropriate.
    columns = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
        39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
        57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
        75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92,
        93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
        109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123,
        124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138,
        139, 140, 141, 142
    ]

    decodeColumns: Dict[str, str] = {
        "DESYNPUF_ID": "NULLIF(TRIM(@1), '')",
        "CLM_ID": "NULLIF(TRIM(@2), '')",
        "CLM_FROM_DT": "NULLIF(TRIM(@3), '')",
        "CLM_THRU_DT": "NULLIF(TRIM(@4), '')",
        "ICD9_DGNS_CD_1": "NULLIF(TRIM(@5), '')",
        "ICD9_DGNS_CD_2": "NULLIF(TRIM(@6), '')",
        "ICD9_DGNS_CD_3": "NULLIF(TRIM(@7), '')",
        "ICD9_DGNS_CD_4": "NULLIF(TRIM(@8), '')",
        "ICD9_DGNS_CD_5": "NULLIF(TRIM(@9), '')",
        "ICD9_DGNS_CD_6": "NULLIF(TRIM(@10), '')",
        "ICD9_DGNS_CD_7": "NULLIF(TRIM(@11), '')",
        "ICD9_DGNS_CD_8": "NULLIF(TRIM(@12), '')",
        "PRF_PHYSN_NPI_1": "NULLIF(TRIM(@13), '')",
        "PRF_PHYSN_NPI_2": "NULLIF(TRIM(@14), '')",
        "PRF_PHYSN_NPI_3": "NULLIF(TRIM(@15), '')",
        "PRF_PHYSN_NPI_4": "NULLIF(TRIM(@16), '')",
        "PRF_PHYSN_NPI_5": "NULLIF(TRIM(@17), '')",
        "PRF_PHYSN_NPI_6": "NULLIF(TRIM(@18), '')",
        "PRF_PHYSN_NPI_7": "NULLIF(TRIM(@19), '')",
        "PRF_PHYSN_NPI_8": "NULLIF(TRIM(@20), '')",
        "PRF_PHYSN_NPI_9": "NULLIF(TRIM(@21), '')",
        "PRF_PHYSN_NPI_10": "NULLIF(TRIM(@22), '')",
        "PRF_PHYSN_NPI_11": "NULLIF(TRIM(@23), '')",
        "PRF_PHYSN_NPI_12": "NULLIF(TRIM(@24), '')",
        "PRF_PHYSN_NPI_13": "NULLIF(TRIM(@25), '')",
        "TAX_NUM_1": "NULLIF(TRIM(@26), '')",
        "TAX_NUM_2": "NULLIF(TRIM(@27), '')",
        "TAX_NUM_3": "NULLIF(TRIM(@28), '')",
        "TAX_NUM_4": "NULLIF(TRIM(@29), '')",
        "TAX_NUM_5": "NULLIF(TRIM(@30), '')",
        "TAX_NUM_6": "NULLIF(TRIM(@31), '')",
        "TAX_NUM_7": "NULLIF(TRIM(@32), '')",
        "TAX_NUM_8": "NULLIF(TRIM(@33), '')",
        "TAX_NUM_9": "NULLIF(TRIM(@34), '')",
        "TAX_NUM_10": "NULLIF(TRIM(@35), '')",
        "TAX_NUM_11": "NULLIF(TRIM(@36), '')",
        "TAX_NUM_12": "NULLIF(TRIM(@37), '')",
        "TAX_NUM_13": "NULLIF(TRIM(@38), '')",
        "HCPCS_CD_1": "NULLIF(TRIM(@39), '')",
        "HCPCS_CD_2": "NULLIF(TRIM(@40), '')",
        "HCPCS_CD_3": "NULLIF(TRIM(@41), '')",
        "HCPCS_CD_4": "NULLIF(TRIM(@42), '')",
        "HCPCS_CD_5": "NULLIF(TRIM(@43), '')",
        "HCPCS_CD_6": "NULLIF(TRIM(@44), '')",
        "HCPCS_CD_7": "NULLIF(TRIM(@45), '')",
        "HCPCS_CD_8": "NULLIF(TRIM(@46), '')",
        "HCPCS_CD_9": "NULLIF(TRIM(@47), '')",
        "HCPCS_CD_10": "NULLIF(TRIM(@48), '')",
        "HCPCS_CD_11": "NULLIF(TRIM(@49), '')",
        "HCPCS_CD_12": "NULLIF(TRIM(@50), '')",
        "HCPCS_CD_13": "NULLIF(TRIM(@51), '')",
        "LINE_NCH_PMT_AMT_1": "NULLIF(TRIM(@52), '')",
        "LINE_NCH_PMT_AMT_2": "NULLIF(TRIM(@53), '')",
        "LINE_NCH_PMT_AMT_3": "NULLIF(TRIM(@54), '')",
        "LINE_NCH_PMT_AMT_4": "NULLIF(TRIM(@55), '')",
        "LINE_NCH_PMT_AMT_5": "NULLIF(TRIM(@56), '')",
        "LINE_NCH_PMT_AMT_6": "NULLIF(TRIM(@57), '')",
        "LINE_NCH_PMT_AMT_7": "NULLIF(TRIM(@58), '')",
        "LINE_NCH_PMT_AMT_8": "NULLIF(TRIM(@59), '')",
        "LINE_NCH_PMT_AMT_9": "NULLIF(TRIM(@60), '')",
        "LINE_NCH_PMT_AMT_10": "NULLIF(TRIM(@61), '')",
        "LINE_NCH_PMT_AMT_11": "NULLIF(TRIM(@62), '')",
        "LINE_NCH_PMT_AMT_12": "NULLIF(TRIM(@63), '')",
        "LINE_NCH_PMT_AMT_13": "NULLIF(TRIM(@64), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_1": "NULLIF(TRIM(@65), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_2": "NULLIF(TRIM(@66), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_3": "NULLIF(TRIM(@67), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_4": "NULLIF(TRIM(@68), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_5": "NULLIF(TRIM(@69), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_6": "NULLIF(TRIM(@70), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_7": "NULLIF(TRIM(@71), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_8": "NULLIF(TRIM(@72), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_9": "NULLIF(TRIM(@73), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_10": "NULLIF(TRIM(@74), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_11": "NULLIF(TRIM(@75), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_12": "NULLIF(TRIM(@76), '')",
        "LINE_BENE_PTB_DDCTBL_AMT_13": "NULLIF(TRIM(@77), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_1": "NULLIF(TRIM(@78), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_2": "NULLIF(TRIM(@79), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_3": "NULLIF(TRIM(@80), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_4": "NULLIF(TRIM(@81), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_5": "NULLIF(TRIM(@82), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_6": "NULLIF(TRIM(@83), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_7": "NULLIF(TRIM(@84), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_8": "NULLIF(TRIM(@85), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_9": "NULLIF(TRIM(@86), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_10": "NULLIF(TRIM(@87), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_11": "NULLIF(TRIM(@88), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_12": "NULLIF(TRIM(@89), '')",
        "LINE_BENE_PRMRY_PYR_PD_AMT_13": "NULLIF(TRIM(@90), '')",
        "LINE_COINSRNC_AMT_1": "NULLIF(TRIM(@91), '')",
        "LINE_COINSRNC_AMT_2": "NULLIF(TRIM(@92), '')",
        "LINE_COINSRNC_AMT_3": "NULLIF(TRIM(@93), '')",
        "LINE_COINSRNC_AMT_4": "NULLIF(TRIM(@94), '')",
        "LINE_COINSRNC_AMT_5": "NULLIF(TRIM(@95), '')",
        "LINE_COINSRNC_AMT_6": "NULLIF(TRIM(@96), '')",
        "LINE_COINSRNC_AMT_7": "NULLIF(TRIM(@97), '')",
        "LINE_COINSRNC_AMT_8": "NULLIF(TRIM(@98), '')",
        "LINE_COINSRNC_AMT_9": "NULLIF(TRIM(@99), '')",
        "LINE_COINSRNC_AMT_10": "NULLIF(TRIM(@100), '')",
        "LINE_COINSRNC_AMT_11": "NULLIF(TRIM(@101), '')",
        "LINE_COINSRNC_AMT_12": "NULLIF(TRIM(@102), '')",
        "LINE_COINSRNC_AMT_13": "NULLIF(TRIM(@103), '')",
        "LINE_ALOWD_CHRG_AMT_1": "NULLIF(TRIM(@104), '')",
        "LINE_ALOWD_CHRG_AMT_2": "NULLIF(TRIM(@105), '')",
        "LINE_ALOWD_CHRG_AMT_3": "NULLIF(TRIM(@106), '')",
        "LINE_ALOWD_CHRG_AMT_4": "NULLIF(TRIM(@107), '')",
        "LINE_ALOWD_CHRG_AMT_5": "NULLIF(TRIM(@108), '')",
        "LINE_ALOWD_CHRG_AMT_6": "NULLIF(TRIM(@109), '')",
        "LINE_ALOWD_CHRG_AMT_7": "NULLIF(TRIM(@110), '')",
        "LINE_ALOWD_CHRG_AMT_8": "NULLIF(TRIM(@111), '')",
        "LINE_ALOWD_CHRG_AMT_9": "NULLIF(TRIM(@112), '')",
        "LINE_ALOWD_CHRG_AMT_10": "NULLIF(TRIM(@113), '')",
        "LINE_ALOWD_CHRG_AMT_11": "NULLIF(TRIM(@114), '')",
        "LINE_ALOWD_CHRG_AMT_12": "NULLIF(TRIM(@115), '')",
        "LINE_ALOWD_CHRG_AMT_13": "NULLIF(TRIM(@116), '')",
        "LINE_PRCSG_IND_CD_1": "NULLIF(TRIM(@117), '')",
        "LINE_PRCSG_IND_CD_2": "NULLIF(TRIM(@118), '')",
        "LINE_PRCSG_IND_CD_3": "NULLIF(TRIM(@119), '')",
        "LINE_PRCSG_IND_CD_4": "NULLIF(TRIM(@120), '')",
        "LINE_PRCSG_IND_CD_5": "NULLIF(TRIM(@121), '')",
        "LINE_PRCSG_IND_CD_6": "NULLIF(TRIM(@122), '')",
        "LINE_PRCSG_IND_CD_7": "NULLIF(TRIM(@123), '')",
        "LINE_PRCSG_IND_CD_8": "NULLIF(TRIM(@124), '')",
        "LINE_PRCSG_IND_CD_9": "NULLIF(TRIM(@125), '')",
        "LINE_PRCSG_IND_CD_10": "NULLIF(TRIM(@126), '')",
        "LINE_PRCSG_IND_CD_11": "NULLIF(TRIM(@127), '')",
        "LINE_PRCSG_IND_CD_12": "NULLIF(TRIM(@128), '')",
        "LINE_PRCSG_IND_CD_13": "NULLIF(TRIM(@129), '')",
        "LINE_ICD9_DGNS_CD_1": "NULLIF(TRIM(@130), '')",
        "LINE_ICD9_DGNS_CD_2": "NULLIF(TRIM(@131), '')",
        "LINE_ICD9_DGNS_CD_3": "NULLIF(TRIM(@132), '')",
        "LINE_ICD9_DGNS_CD_4": "NULLIF(TRIM(@133), '')",
        "LINE_ICD9_DGNS_CD_5": "NULLIF(TRIM(@134), '')",
        "LINE_ICD9_DGNS_CD_6": "NULLIF(TRIM(@135), '')",
        "LINE_ICD9_DGNS_CD_7": "NULLIF(TRIM(@136), '')",
        "LINE_ICD9_DGNS_CD_8": "NULLIF(TRIM(@137), '')",
        "LINE_ICD9_DGNS_CD_9": "NULLIF(TRIM(@138), '')",
        "LINE_ICD9_DGNS_CD_10": "NULLIF(TRIM(@139), '')",
        "LINE_ICD9_DGNS_CD_11": "NULLIF(TRIM(@140), '')",
        "LINE_ICD9_DGNS_CD_12": "NULLIF(TRIM(@141), '')",
        "LINE_ICD9_DGNS_CD_13": "NULLIF(TRIM(@142), '')"
    }

    # 4) Perform the import
    logger.info("Starting util.import_table → %s.%s (threads=%d)", schema, table, threads)
    report: Any = util.import_table(
        wildcard,
        {
            "schema": schema,
            "table": table,
            "columns": columns,
            "decodeColumns": decodeColumns,
            "threads": threads,
            "dialect": "csv",
            "skipRows": 1,
            "fieldsTerminatedBy": ",",
            "linesTerminatedBy": "\r\n",
            "characterSet": "utf8mb4",
        },
    )

    # 5) Summarize warnings and results
    try:
        warnings = session.run_sql("SHOW WARNINGS LIMIT 10")
        logger.info("Recent WARNINGS (up to 10): %s", warnings)
    except Exception as e:
        logger.warning("Could not fetch SHOW WARNINGS: %s", e)

    logger.info("Import finished. Summary: %s", report)

    # (Optional historical performance sample for context)
    logger.debug(
        "Historical sample results (for reference only): "
        "10 files (12.37 GB) imported in ~1–5 hours; rows ≈ 23.7M; warnings minimal."
    )
