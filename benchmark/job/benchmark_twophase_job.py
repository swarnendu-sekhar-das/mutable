#!/usr/bin/env python3
"""
Benchmark TwoPhaseOptimizer on IMDB JOB (Join Order Benchmark) dataset.

Measures optimization time, enumeration time, and plan cost across all available
plan enumerators in mutable, using --dryrun mode (schema loaded, execution skipped).

This avoids ASan crashes in the release build while still providing meaningful
performance comparison of the optimization phase — the core value of TwoPhaseOptimizer.

Usage:
    python3 benchmark/job/benchmark_twophase_job.py [--enumerators E1,E2,...] [--timeout SECS] [--runs N]
"""

import subprocess
import re
import os
import sys
import yaml
import csv
import time
import signal
import argparse
from pathlib import Path
from datetime import datetime

# ----- Configuration -----
SHELL_BINARY = os.path.join('build', 'release', 'bin', 'shell')
JOB_DIR = os.path.join('benchmark', 'job')
SCHEMA_FILE = os.path.join('benchmark', 'job', 'data', 'schema_no_import.sql')
SCHEMA_FILE_FULL = os.path.join('benchmark', 'job', 'data', 'schema.sql')

ALL_ENUMERATORS = [
    'TwoPhaseOptimizer',
    'DPccp',
    'GOO',
    'IKKBZ',
    'LinearizedDP',
    'TDGOO',
    'TDbasic',
    'TDMinCutAGaT',
    'HeuristicSearch',
    'DPsize',
    'DPsub',
    'DPsizeOpt',
    'DPsubOpt',
    'DPsizeSub',
    'PEall',
]

DEFAULT_TIMEOUT = 120   # seconds per query
DEFAULT_RUNS = 3        # number of runs per (query, enumerator) pair
OUTPUT_CSV = 'job_twophase_benchmark.csv'

# ----- Regex patterns for parsing shell output -----
OPT_PATTERN = re.compile(r'^Compute the logical query plan:\s+([\d.]+)')
ENUM_PATTERN = re.compile(r'^Plan enumeration:\s+([\d.]+)')
PLAN_COST_PATTERN = re.compile(r'^Plan cost:\s+([\d.eE+\-]+)')
SEMA_PATTERN = re.compile(r'^Semantic analysis:\s+([\d.]+)')


def load_job_queries():
    """Load all JOB queries from YAML files in benchmark/job/."""
    queries = {}
    for yml_file in sorted(Path(JOB_DIR).glob('q*.yml')):
        with open(yml_file) as f:
            yml = yaml.safe_load(f)
        query_name = yml_file.stem
        cases = yml.get('cases', {})
        for case_name, sql in cases.items():
            full_name = f"{query_name}{case_name}"
            queries[full_name] = sql.strip()
    return queries


def transform_query(sql):
    """
    Transform a JOB query for mutable compatibility:
    - Replace SELECT ... FROM with SELECT * FROM
    - Keep only equi-join predicates (alias.col = alias.col) and
      simple numeric comparisons
    """
    sql_upper = sql.upper()
    from_pos = sql_upper.find('FROM')
    where_pos = sql_upper.find('WHERE')

    if from_pos == -1:
        return None

    from_clause = sql[from_pos:where_pos] if where_pos != -1 else sql[from_pos:]
    where_clause = sql[where_pos + 5:] if where_pos != -1 else ''

    # Extract equi-join predicates (alias.col = alias.col)
    join_pred_pattern = re.compile(r'(\w+\.\w+)\s*=\s*(\w+\.\w+)')
    join_predicates = []
    for match in join_pred_pattern.finditer(where_clause):
        left, right = match.group(1), match.group(2)
        if left.split('.')[0] != right.split('.')[0]:
            join_predicates.append(f"{left} = {right}")

    if not join_predicates:
        return None

    where_str = ' AND '.join(join_predicates)
    return f"SELECT * {from_clause.strip()} WHERE {where_str};"


def count_tables(sql):
    """Count number of tables in the FROM clause."""
    m = re.search(r'FROM\s+(.*?)(?:WHERE|$)', sql, re.IGNORECASE | re.DOTALL)
    if m:
        return len([t.strip() for t in m.group(1).split(',') if t.strip()])
    return 0


def run_query_dryrun(enumerator, query_sql, schema_sql, timeout_sec):
    """
    Run a single query in --dryrun mode.
    Returns dict with opt_time, enum_time, plan_cost, sema_time, error.
    """
    command = [
        SHELL_BINARY,
        '--dryrun', '--benchmark', '--times',
        '--plan-enumerator', enumerator,
        '--quiet', '-'
    ]

    # Schema creates the DB and tables (no data loaded in dryrun);
    # then execute the query
    full_input = schema_sql + '\n' + query_sql + '\n'

    try:
        result = subprocess.run(
            command,
            input=full_input,
            capture_output=True,
            text=True,
            timeout=timeout_sec
        )
        output = result.stdout + result.stderr

        metrics = {
            'opt_time': None,
            'enum_time': None,
            'plan_cost': None,
            'sema_time': None,
            'error': None
        }

        for line in output.split('\n'):
            line = line.strip()
            m = OPT_PATTERN.match(line)
            if m:
                metrics['opt_time'] = float(m.group(1))
            m = ENUM_PATTERN.match(line)
            if m:
                metrics['enum_time'] = float(m.group(1))
            m = PLAN_COST_PATTERN.match(line)
            if m:
                metrics['plan_cost'] = float(m.group(1))
            m = SEMA_PATTERN.match(line)
            if m:
                metrics['sema_time'] = float(m.group(1))

        if metrics['opt_time'] is None:
            error_lines = [l for l in output.split('\n')
                           if 'error' in l.lower() or 'exception' in l.lower()]
            metrics['error'] = error_lines[0][:200] if error_lines else 'no timing output'

        return metrics

    except subprocess.TimeoutExpired:
        return {'opt_time': None, 'enum_time': None, 'plan_cost': None,
                'sema_time': None, 'error': f'timeout ({timeout_sec}s)'}
    except Exception as e:
        return {'opt_time': None, 'enum_time': None, 'plan_cost': None,
                'sema_time': None, 'error': str(e)[:200]}


def load_completed(csv_file):
    """Load already completed (query, enumerator, run) combos from CSV to allow resuming."""
    completed = set()
    if os.path.isfile(csv_file):
        with open(csv_file, newline='') as f:
            reader = csv.DictReader(f)
            for row in reader:
                key = (row['query'], row['enumerator'], int(row['run']))
                completed.add(key)
    return completed


def main():
    parser = argparse.ArgumentParser(description='Benchmark TwoPhaseOptimizer on IMDB JOB')
    parser.add_argument('--enumerators', type=str, default=None,
                        help='Comma-separated list of enumerators (default: all)')
    parser.add_argument('--timeout', type=int, default=DEFAULT_TIMEOUT,
                        help=f'Timeout per query in seconds (default: {DEFAULT_TIMEOUT})')
    parser.add_argument('--runs', type=int, default=DEFAULT_RUNS,
                        help=f'Number of runs per query/enumerator (default: {DEFAULT_RUNS})')
    parser.add_argument('--output', type=str, default=OUTPUT_CSV,
                        help=f'Output CSV file (default: {OUTPUT_CSV})')
    parser.add_argument('--resume', action='store_true',
                        help='Resume from existing CSV (skip completed queries)')
    args = parser.parse_args()

    # Select enumerators
    if args.enumerators:
        enumerators = [e.strip() for e in args.enumerators.split(',')]
    else:
        enumerators = ALL_ENUMERATORS

    # Validate prerequisites
    if not os.path.isfile(SHELL_BINARY):
        print(f"ERROR: Shell binary not found at {SHELL_BINARY}")
        sys.exit(1)

    # Auto-generate stripped schema (no IMPORT statements) for dryrun mode
    if not os.path.isfile(SCHEMA_FILE):
        if os.path.isfile(SCHEMA_FILE_FULL):
            print(f"Generating {SCHEMA_FILE} from {SCHEMA_FILE_FULL} (stripping IMPORT lines)...")
            with open(SCHEMA_FILE_FULL) as f:
                lines = f.readlines()
            with open(SCHEMA_FILE, 'w') as f:
                for line in lines:
                    if not line.strip().upper().startswith('IMPORT'):
                        f.write(line)
            print(f"  Created {SCHEMA_FILE}")
        else:
            print(f"ERROR: Schema file not found at {SCHEMA_FILE} or {SCHEMA_FILE_FULL}")
            print("Run: python3 benchmark/get_data.py job")
            sys.exit(1)

    # Read schema (without IMPORT lines — dryrun only needs table definitions)
    with open(SCHEMA_FILE) as f:
        schema_sql = f.read()

    # Load and transform queries
    raw_queries = load_job_queries()
    queries = {}
    skipped = 0
    for name, sql in raw_queries.items():
        transformed = transform_query(sql)
        if transformed:
            queries[name] = (transformed, count_tables(transformed))
        else:
            skipped += 1

    sorted_queries = sorted(queries.keys())

    # Load completed work if resuming
    completed = set()
    if args.resume:
        completed = load_completed(args.output)
        print(f"Resuming: {len(completed)} query-runs already completed.")

    # Initialize CSV (write header if new file)
    write_header = not (args.resume and os.path.isfile(args.output))
    if write_header:
        with open(args.output, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['query', 'num_tables', 'enumerator', 'run',
                             'opt_time_ms', 'enum_time_ms', 'plan_cost',
                             'sema_time_ms', 'status', 'timestamp'])

    # Print header
    print("=" * 80)
    print("  IMDB JOB Benchmark: TwoPhaseOptimizer vs All Enumerators")
    print(f"  Mode: --dryrun (optimization time only)")
    print(f"  Queries: {len(queries)} ({skipped} skipped as non-transformable)")
    print(f"  Enumerators: {len(enumerators)}")
    print(f"  Runs per query: {args.runs}")
    print(f"  Timeout: {args.timeout}s per query")
    print(f"  Output: {args.output}")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)

    # Tracking stats
    stats = {e: {'success': 0, 'fail': 0, 'timeout': 0,
                 'total_opt': 0.0, 'total_enum': 0.0,
                 'min_opt': float('inf'), 'max_opt': 0.0}
             for e in enumerators}

    total_combos = len(sorted_queries) * len(enumerators) * args.runs
    done = 0
    start_time = time.time()

    for enumerator in enumerators:
        print(f"\n{'─' * 80}")
        print(f"  Enumerator: {enumerator}")
        print(f"{'─' * 80}")

        for q_idx, query_name in enumerate(sorted_queries, 1):
            query_sql, num_tables = queries[query_name]

            for run in range(args.runs):
                done += 1
                key = (query_name, enumerator, run)

                if key in completed:
                    continue

                # Run the query
                metrics = run_query_dryrun(enumerator, query_sql, schema_sql, args.timeout)

                # Determine status
                if metrics['error']:
                    if 'timeout' in str(metrics['error']).lower():
                        status = 'TIMEOUT'
                        stats[enumerator]['timeout'] += 1
                    else:
                        status = f"ERROR: {metrics['error'][:80]}"
                        stats[enumerator]['fail'] += 1
                else:
                    status = 'SUCCESS'
                    stats[enumerator]['success'] += 1
                    stats[enumerator]['total_opt'] += metrics['opt_time']
                    if metrics['enum_time']:
                        stats[enumerator]['total_enum'] += metrics['enum_time']
                    stats[enumerator]['min_opt'] = min(stats[enumerator]['min_opt'],
                                                       metrics['opt_time'])
                    stats[enumerator]['max_opt'] = max(stats[enumerator]['max_opt'],
                                                       metrics['opt_time'])

                # Save to CSV immediately (crash-safe)
                with open(args.output, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow([
                        query_name, num_tables, enumerator, run,
                        f"{metrics['opt_time']:.3f}" if metrics['opt_time'] is not None else "",
                        f"{metrics['enum_time']:.3f}" if metrics['enum_time'] is not None else "",
                        f"{metrics['plan_cost']:.6g}" if metrics['plan_cost'] is not None else "",
                        f"{metrics['sema_time']:.3f}" if metrics['sema_time'] is not None else "",
                        status,
                        datetime.now().strftime('%H:%M:%S')
                    ])

                # Progress output
                elapsed = time.time() - start_time
                rate = done / elapsed if elapsed > 0 else 0
                eta = (total_combos - done) / rate if rate > 0 else 0

                if run == 0:  # Only print first run to reduce noise
                    if status == 'SUCCESS':
                        enum_str = f"{metrics['enum_time']:8.3f}" if metrics['enum_time'] is not None else "     N/A"
                        cost_str = f"{metrics['plan_cost']:.2f}" if metrics['plan_cost'] is not None else "N/A"
                        print(f"  [{q_idx:3d}/{len(sorted_queries)}] {query_name:8s} "
                              f"({num_tables:2d}T): "
                              f"opt={metrics['opt_time']:8.3f}ms  "
                              f"enum={enum_str}ms  "
                              f"cost={cost_str}  "
                              f"[{done}/{total_combos} ETA:{eta/60:.0f}m]")
                    else:
                        print(f"  [{q_idx:3d}/{len(sorted_queries)}] {query_name:8s} "
                              f"({num_tables:2d}T): {status[:60]}  "
                              f"[{done}/{total_combos}]")

    # ============ Summary ============
    total_elapsed = time.time() - start_time
    print(f"\n{'=' * 80}")
    print("  BENCHMARK SUMMARY")
    print(f"  Total wall time: {total_elapsed/60:.1f} minutes")
    print(f"{'=' * 80}")
    print(f"\n  {'Enumerator':<25s} {'OK':>5s} {'Fail':>5s} {'Tout':>5s} "
          f"{'Avg Opt(ms)':>12s} {'Avg Enum(ms)':>12s} {'Min Opt':>10s} {'Max Opt':>10s}")
    print(f"  {'─' * 95}")

    for e in enumerators:
        s = stats[e]
        n = s['success'] if s['success'] > 0 else 1
        avg_opt = s['total_opt'] / n
        avg_enum = s['total_enum'] / n
        min_opt = s['min_opt'] if s['min_opt'] != float('inf') else 0
        print(f"  {e:<25s} {s['success']:5d} {s['fail']:5d} {s['timeout']:5d} "
              f"{avg_opt:12.3f} {avg_enum:12.3f} {min_opt:10.3f} {s['max_opt']:10.3f}")

    print(f"\n  Results saved to: {args.output}")
    print(f"  Generate report: python3 benchmark/job/generate_twophase_report.py")


if __name__ == '__main__':
    main()
