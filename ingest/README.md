
# Ingestion — Parallel CSV → MySQL (Sample)

**© 2025 Ryan Shaffer. All rights reserved.**  
**SAMPLE INGESTION ONLY** — The full, production ETL/DDL codebase for writing this database to MySQL will be published soon in a separate repository.

This folder contains a minimal, well-documented sample for bulk‑loading `carrier_claims` CSV files into MySQL using **MySQL Shell (mysqlsh) Classic Protocol** and `util.import_table`. It is designed to be: secure (no hard‑coded secrets or paths), reproducible, and easy to run from the shell.

> **Scope**: This is a focused ingestion sample for the `carrier_claims` domain. It does not include schema DDL, downstream transforms, validations, or orchestration. Those live in the upcoming repository.

---

## Files

- `example_carrier_claims_parallel_load_functions.py` — Core import function `load_csv_folder_classic_protocol(...)`.  
- `example_carrier_claims_parallel_load_call.py` — Shell‑friendly entrypoint that wires CLI flags/ENV to the function.

---

## Quick Start

1. **Open MySQL Shell in Python mode (Classic Protocol):**
   ```bash
   mysqlsh --uri user@host:3306 -p --py
   ```
   *Classic Protocol* (TCP 3306) is required to support `LOCAL INFILE` semantics for `util.import_table`.

2. **Run the caller with your parameters:**
   ```bash
   mysqlsh --uri user@host:3306 -p --py -f example_carrier_claims_parallel_load_call.py --        --folder "/path/to/CarrierClaims"        --schema synpuf        --table carrier_claims        --threads 8        --pattern "*.csv"
   ```

3. **Alternatively, use environment variables:**
   ```bash
   # Windows cmd/PowerShell:
   set DATA_DIR=C:\data\CarrierClaims
   set THREADS=8

   # bash/zsh:
   export DATA_DIR="/data/CarrierClaims"
   export THREADS=8

   mysqlsh --uri user@host:3306 -p --py -f example_carrier_claims_parallel_load_call.py --        --schema synpuf --table carrier_claims
   ```

---

## Assumptions & Dependencies (what and why)

- **MySQL Shell 8.0/8.4** running in **Classic Protocol** (`mysqlsh --py` connected to port 3306).  
  *Why*: `LOCAL INFILE` and `util.import_table` require Classic Protocol for local file ingestion.
- **Active session provided by mysqlsh**. The scripts do not create or manage connections; they assume `session`/`util` are available in `__main__`.
- **`local_infile=ON`** on the server. Required to read local CSVs.
- **CSV layout** corresponds to the `carrier_claims` columns (sample `decodeColumns` included). Empty strings are normalized to `NULL` for safer downstream SQL.
- **No machine‑specific details in code** — paths and secrets are passed via CLI or environment variables.

---

## Security & Secrets

- **No plaintext credentials** in code. Use `-p` in `mysqlsh` to be prompted securely.  
- **No absolute paths** embedded. Provide paths via `--folder` or `DATA_DIR`.
- The code is intended to be committed safely to version control without risk of leaking secrets.

---

## Consistent Style (what that means here)

- **PEP 8** naming and **type hints** for public functions.
- **Logging** at INFO level (no `print`) to keep outputs consistent and greppable.
- **f‑strings** and `pathlib` for readability; no mutation of user inputs.
- **Single responsibility**: the functions focus on import mechanics; the caller handles argument parsing.

---

## Performance Expectations (brief)

- Throughput depends primarily on disk and CPU. **NVMe** drives scale better than HDD/USB.
- Start with **`--threads 8`** for multi‑file folders; adjust based on I/O contention (typical range 4–12).
- Scaling is **sub‑linear**; single large files won’t benefit from very high thread counts.
- Use `SHOW WARNINGS` to inspect row/parse issues; monitor row counts after load.

---

## Parameters

| Parameter  | Where set | Required | Default            | Notes |
|-----------:|-----------|:--------:|--------------------|------|
| `folder`   | CLI/ENV   | ✅       | `DATA_DIR` (if set) | Directory containing CSVs. |
| `schema`   | CLI       | ✅       | —                  | Target MySQL schema. |
| `table`    | CLI       | ✅       | —                  | Target MySQL table. |
| `threads`  | CLI/ENV   | ❌       | `8` or `THREADS`   | Parallelism hint for `util.import_table`. |
| `pattern`  | CLI       | ❌       | `*.csv`            | Glob for selecting input files. |

**CSV Dialect (current defaults in code)**:  
- `fieldsTerminatedBy=","`  
- `linesTerminatedBy="\r\n"` (Windows‑style; you can switch to `\n` if needed)  
- `characterSet="utf8mb4"`  
- `skipRows=1` (header row skipped)

---

## What the Function Does

`load_csv_folder_classic_protocol(folder, schema, table, threads, pattern="*.csv")`

- Enumerates files under `folder` matching `pattern` and logs the list.  
- Configures `columns` and `decodeColumns` to normalize blanks → `NULL`.  
- Calls `util.import_table(...)` with your schema/table and thread settings.  
- Logs a brief summary and attempts to show recent warnings via `SHOW WARNINGS`.

> **Return type**: `None` — progress and results are surfaced via logging. If you need a structured return (e.g., row counts, duration), this can be added later without breaking current behavior.

---

## Validation & Quality Tips (optional, but recommended)

- Confirm `local_infile=ON` and Classic Protocol connection before running.
- `DESCRIBE schema.table;` and verify column count aligns with CSV header.
- Validate row counts after import; keep a small **control CSV** to sanity‑check performance and decoding.
- Consider loading into a **staging** table and swapping via `RENAME TABLE` for idempotent reruns.

---

## Troubleshooting

- **“No CSV files found”**: check `--folder` and `--pattern`; verify `DATA_DIR` is set if you didn’t pass `--folder`.
- **Permission or LOCAL INFILE errors**: ensure server `local_infile=ON`; verify Classic Protocol (not X Protocol).
- **Weird characters/encoding**: confirm `characterSet="utf8mb4"` and the source CSV encoding; adjust if needed.
- **Newlines mismatch**: if files are Unix‑style, update `linesTerminatedBy="\n"`.
- **Performance stalls**: reduce `--threads` for single large files or when disk contention is high.

---

## Example Commands

**Windows (PowerShell)**
```powershell
set DATA_DIR=C:\data\CarrierClaims
mysqlsh --uri root@localhost:3306 -p --py -f example_carrier_claims_parallel_load_call.py -- `
  --schema synpuf --table carrier_claims --threads 8
```

**macOS/Linux (bash/zsh)**
```bash
export DATA_DIR="/data/CarrierClaims"
mysqlsh --uri root@localhost:3306 -p --py -f example_carrier_claims_parallel_load_call.py --   --schema synpuf --table carrier_claims --threads 8
```

---

## Roadmap (what will appear in the full repo)

- End‑to‑end ETL (schema DDL, constraints, indexes).  
- Data quality checks, reject‑files, and per‑file metrics.  
- Staging → production swap with idempotent reruns.  
- Containerized runner and CI checks.  

---

## License & Copyright

**© 2025 Ryan Shaffer. All rights reserved.**  
This sample is provided for demonstration only and is subject to copyright. The complete codebase, with its final license and usage terms, will be published in the forthcoming repository.
