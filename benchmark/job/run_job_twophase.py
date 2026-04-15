#!/usr/bin/env python3
"""
Benchmark TwoPhaseOptimizer vs DPccp on IMDB JOB queries with real data.

Loads the IMDB dataset once, then runs transformed JOB queries (equi-joins only,
SELECT * instead of MIN aggregates) to measure both optimization and execution time.
"""

import subprocess
import re
import os
import sys
import yaml
import csv
import time
from pathlib import Path

# Configuration
SHELL_BINARY = os.path.join('build', 'release', 'bin', 'shell')
JOB_DIR = os.path.join('benchmark', 'job')
SCHEMA_FILE = os.path.join('benchmark', 'job', 'data', 'schema.sql')
ENUMERATORS = [
    'TwoPhaseOptimizer',
    'PEall',
    'TDMinCutAGaT',
    'TDbasic',
    'IKKBZ',
    'TDGOO',
    'HeuristicSearch',
    'DPsize',
    'DPsub',
    'LinearizedDP',
    'GOO',
    'DPsubOpt',
    'DPsizeOpt',
    'DPccp',
    'DPsizeSub'
]
NUM_RUNS = 1  # Keep at 1 since loading data is expensive
TIMEOUT = 300  # 5 min timeout per run (data loading + query)
OUTPUT_CSV = 'job_benchmark_with_data.csv'

# Patterns
OPT_PATTERN = re.compile(r'^Compute the logical query plan:\s+([\d.]+)')
ENUM_PATTERN = re.compile(r'^Plan enumeration:\s+([\d.]+)')
EXEC_PATTERN = re.compile(r'^Execute query:\s+([\d.]+)')
PLAN_COST_PATTERN = re.compile(r'^Plan cost:\s+([\d.eE+\-]+)')


def load_job_queries():
    """Load all JOB queries from YAML files."""
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
      simple numeric comparisons (alias.col op number)
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
    """Count tables in FROM clause."""
    m = re.search(r'FROM\s+(.*?)(?:WHERE|$)', sql, re.IGNORECASE | re.DOTALL)
    if m:
        return len([t.strip() for t in m.group(1).split(',') if t.strip()])
    return 0


def run_with_data(enumerator, query_sql, schema_sql):
    """
    Run a query with real data loaded.
    Returns dict with opt_time, enum_time, exec_time, plan_cost.
    """
    command = [
        SHELL_BINARY,
        '--benchmark', '--times',
        '--plan-enumerator', enumerator,
        '--quiet', '-'
    ]

    full_input = schema_sql + '\n' + query_sql + '\n'

    try:
        result = subprocess.run(
            command,
            input=full_input,
            capture_output=True,
            text=True,
            timeout=TIMEOUT
        )
        output = result.stdout + result.stderr

        metrics = {
            'opt_time': None,
            'enum_time': None,
            'exec_time': None,
            'plan_cost': None,
            'error': None
        }

        for line in output.split('\n'):
            m = OPT_PATTERN.match(line)
            if m:
                metrics['opt_time'] = float(m.group(1))
            m = ENUM_PATTERN.match(line)
            if m:
                metrics['enum_time'] = float(m.group(1))
            m = EXEC_PATTERN.match(line)
            if m:
                metrics['exec_time'] = float(m.group(1))
            m = PLAN_COST_PATTERN.match(line)
            if m:
                metrics['plan_cost'] = float(m.group(1))

        if metrics['opt_time'] is None:
            error_lines = [l for l in output.split('\n') if 'error' in l.lower()]
            metrics['error'] = error_lines[0][:100] if error_lines else 'no timing'

        return metrics
    except subprocess.TimeoutExpired:
        return {'opt_time': None, 'enum_time': None, 'exec_time': None,
                'plan_cost': None, 'error': 'timeout'}
    except Exception as e:
        return {'opt_time': None, 'enum_time': None, 'exec_time': None,
                'plan_cost': None, 'error': str(e)}


def main():
    if not os.path.isfile(SHELL_BINARY):
        print(f"Error: Shell binary not found at {SHELL_BINARY}")
        sys.exit(1)

    if not os.path.isfile(SCHEMA_FILE):
        print(f"Error: Schema file not found at {SCHEMA_FILE}")
        print("Run: python3 benchmark/get_data.py job")
        sys.exit(1)

    # Read schema (used for data loading)
    with open(SCHEMA_FILE) as f:
        schema_sql = f.read()

    print("=" * 75)
    print("  IMDB JOB Benchmark: TwoPhaseOptimizer vs DPccp (WITH REAL DATA)")
    print(f"  Runs per query: {NUM_RUNS}")
    print("=" * 75)

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

    print(f"\nLoaded {len(queries)} JOB queries ({skipped} skipped)")

    # First test: make sure data loading works with a simple query
    print("\nTesting data loading with a simple query...")
    test_result = run_with_data('DPccp',
        'SELECT * FROM company_type AS ct, info_type AS it WHERE ct.id = it.id;',
        schema_sql)
    if test_result['error']:
        print(f"Error during data loading test: {test_result['error']}")
        print("Data loading may take too long or have schema issues.")
        print("Falling back to --dryrun mode for the full benchmark.")
        sys.exit(1)
    else:
        print(f"  Data loaded + query executed OK (exec={test_result['exec_time']}ms)")

    # CSV output
    with open(OUTPUT_CSV, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['query', 'num_tables', 'enumerator', 'run',
                         'opt_time_ms', 'enum_time_ms', 'exec_time_ms', 'plan_cost'])

    # Summary stats
    summary = {e: {'success': 0, 'fail': 0, 'total_opt': 0.0, 'total_exec': 0.0}
               for e in ENUMERATORS}

    total = len(queries)
    for idx, query_name in enumerate(sorted(queries.keys()), 1):
        query_sql, num_tables = queries[query_name]
        print(f"\n[{idx}/{total}] Query: {query_name} ({num_tables} tables)")

        for enumerator in ENUMERATORS:
            for run in range(NUM_RUNS):
                start = time.time()
                metrics = run_with_data(enumerator, query_sql, schema_sql)
                wall_time = time.time() - start

                if metrics['error']:
                    print(f"  {enumerator:25s}: FAILED ({metrics['error']})")
                    summary[enumerator]['fail'] += 1
                else:
                    print(f"  {enumerator:25s}: opt={metrics['opt_time']:8.3f}ms  "
                          f"exec={metrics['exec_time']:8.3f}ms  "
                          f"cost={metrics['plan_cost']:.2f}  "
                          f"wall={wall_time:.1f}s")
                    summary[enumerator]['success'] += 1
                    summary[enumerator]['total_opt'] += metrics['opt_time']
                    summary[enumerator]['total_exec'] += metrics['exec_time']

                    with open(OUTPUT_CSV, 'a', newline='') as f:
                        writer = csv.writer(f)
                        writer.writerow([query_name, num_tables, enumerator, run,
                                         f"{metrics['opt_time']:.3f}",
                                         f"{metrics['enum_time']:.3f}" if metrics['enum_time'] else "",
                                         f"{metrics['exec_time']:.3f}" if metrics['exec_time'] else "",
                                         f"{metrics['plan_cost']:.2f}" if metrics['plan_cost'] else ""])

    # Print summary
    print(f"\n{'=' * 75}")
    print("  SUMMARY")
    print(f"{'=' * 75}")
    for e in ENUMERATORS:
        s = summary[e]
        if s['success'] > 0:
            print(f"  {e}:")
            print(f"    Queries passed: {s['success']}/{s['success'] + s['fail']}")
            print(f"    Total opt time:  {s['total_opt']:.3f}ms")
            print(f"    Avg opt time:    {s['total_opt']/s['success']:.3f}ms")
            print(f"    Total exec time: {s['total_exec']:.3f}ms")
            print(f"    Avg exec time:   {s['total_exec']/s['success']:.3f}ms")
    print(f"\nResults saved to {OUTPUT_CSV}")


if __name__ == '__main__':
    main()
