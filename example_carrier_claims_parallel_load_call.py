
# -*- coding: utf-8 -*-
"""
© 2025 Ryan Shaffer. All rights reserved.
SAMPLE INGESTION CALLER — The complete, production ETL/DDL codebase for writing
this database to MySQL will be published soon in a separate repository.

Title
-----
Shell-friendly entrypoint to invoke `load_csv_folder_classic_protocol`.

Dependencies & Assumptions (what and why)
-----------------------------------------
- MySQL Shell 8.0/8.4 running in **Classic Protocol** (`mysqlsh --uri user@host:3306 -p --py`).
  The active session is managed by `mysqlsh`; this script does not open connections.
- The companion module `example_carrier_claims_parallel_load_functions.py` must be
  importable from the current working directory or `PYTHONPATH`.
- Inputs are provided via CLI flags and/or environment variables so no credentials
  or machine-specific paths are hard-coded here.

Keep Credentials & Local Paths Out
----------------------------------
- Use `-p` with `mysqlsh` to prompt for a password securely.
- Provide the folder path via the `--folder` CLI flag or the `DATA_DIR` environment
  variable. Do not hard-code local paths into the script.

Consistent Style (what that means here)
---------------------------------------
- PEP 8 naming, type hints, and argparse for explicit, self-documenting inputs.
- Logging (INFO) instead of prints for consistent, greppable output.
- f-strings for readability.

Performance Expectations (brief)
--------------------------------
- Start with `--threads 8` for multi-file folders. Reduce to 4 for single large files
  or increase cautiously (e.g., 12) if I/O allows. Measure and tune empirically.

How to Run (examples)
---------------------
1) With explicit folder:
   mysqlsh --uri root@localhost:3306 -p --py -f example_carrier_claims_parallel_load_call.py -- \           --folder "/path/to/CarrierClaims" --schema synpuf --table carrier_claims --threads 8 --pattern "*.csv"

2) Using DATA_DIR environment variable (folder=DATA_DIR by default):
   set DATA_DIR=/path/to/CarrierClaims   # PowerShell/cmd: set; bash/zsh: export
   mysqlsh --uri root@localhost:3306 -p --py -f example_carrier_claims_parallel_load_call.py -- \           --schema synpuf --table carrier_claims --threads 8

Copyright
---------
This sample is copyright-protected and provided for demonstration only.
"""
import argparse
import logging
import os
from typing import Optional

# Configure logging once; modules will inherit this root configuration.
if not logging.getLogger().handlers:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

logger = logging.getLogger(__name__)

try:
    from example_carrier_claims_parallel_load_functions import load_csv_folder_classic_protocol
except Exception as exc:
    logger.error("Could not import companion module: %s", exc)
    raise

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Invoke MySQL Shell util.import_table to parallel-load CSVs into a target table."
    )
    parser.add_argument("--folder", type=str, default=os.getenv("DATA_DIR"),
                        help="Folder containing CSV files. Defaults to DATA_DIR if set.")
    parser.add_argument("--schema", type=str, required=True, help="Target MySQL schema name.")
    parser.add_argument("--table", type=str, required=True, help="Target MySQL table name.")
    parser.add_argument("--threads", type=int, default=int(os.getenv("THREADS", "8")),
                        help="Degree of parallelism (default: 8 or env THREADS).")
    parser.add_argument("--pattern", type=str, default="*.csv",
                        help="Glob pattern for files (default: *.csv).")
    return parser.parse_args()

def main() -> None:
    args = parse_args()

    if not args.folder:
        logger.error("No --folder provided and DATA_DIR not set. Aborting.")
        raise SystemExit(2)

    logger.info("Starting import: folder=%s, schema=%s, table=%s, threads=%d, pattern=%s",
                args.folder, args.schema, args.table, args.threads, args.pattern)

    load_csv_folder_classic_protocol(
        folder=args.folder,
        schema=args.schema,
        table=args.table,
        threads=args.threads,
        pattern=args.pattern,
    )

    logger.info("Done. Review warnings above (if any) and validate row counts.")

if __name__ == "__main__":
    main()
