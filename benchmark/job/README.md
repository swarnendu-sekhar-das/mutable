# IMDB JOB Benchmark on Mutable (Two-Phase Optimizer vs DPccp)

This directory contains queries and a benchmarking script to evaluate the performance of our **Two-Phase Optimizer (2PO)** implementation against the default **DPccp** enumerator on the *Join Order Benchmark (JOB)* dataset.

## Prerequisites

Ensure you have successfully built the `mutable` database engine. The benchmark script relies on the `shell` executable located at `build/release/bin/shell`.

Install `pyyaml` (if not already installed) to parse the benchmark query files:
```bash
pip3 install pyyaml
# OR use pipenv from the root directory: pipenv install
```

## Downloading the Dataset

The script requires the IMDB schema to be populated:
```bash
python3 benchmark/get_data.py job
```
This fetches the dataset and prepares the required `benchmark/job/data/schema.sql` file.

## Running the Benchmark

From the **project root directory**, run the benchmark using:
```bash
python3 benchmark/job/run_job_twophase.py
```

### What the script does:
1. It loads all JOB queries (from `.yml` files).
2. It transforms the queries to a native format `mutable` can process (equi-joins).
3. It benchmarks these transformed queries using both the `TwoPhaseOptimizer` and `DPccp` components.
4. It exports metrics (optimization time, execution time, and plan cost) into `job_benchmark_with_data.csv`.

## Troubleshooting

- **`No module named 'yaml'`**: Make sure you installed the python requirements (via `pip3 install pyyaml` or `pipenv`).
- **`shell` binary not found**: Ensure you compiled the release build of Mutable correctly (`make -C build/release`) and the binary is found at `build/release/bin/shell`.
- **Query Timeout**: Data loading might take a few minutes on slow hardware. Wait patiently or increase the `TIMEOUT` threshold inside the script.
