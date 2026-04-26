#!/usr/bin/env python3
import subprocess
import re
import os
import sys
import yaml
import csv
import time
import argparse
from pathlib import Path
from queue import Queue, Empty
from threading import Thread

# Configuration
SHELL_BINARY = os.path.join('build', 'release', 'bin', 'shell')
JOB_DIR = os.path.join('benchmark', 'job')
SCHEMA_FILE = os.path.join('benchmark', 'job', 'data', 'schema.sql')

ALL_ENUMERATORS = [
    'TwoPhaseOptimizer', 'PEall', 'TDMinCutAGaT', 'TDbasic', 'IKKBZ', 
    'TDGOO', 'HeuristicSearch', 'DPsize', 'DPsub', 'LinearizedDP', 'GOO', 
    'DPsubOpt', 'DPsizeOpt', 'DPccp', 'DPsizeSub'
]

OPT_PATTERN = re.compile(r'^Compute the logical query plan:\s+([\d.]+)')
ENUM_PATTERN = re.compile(r'^Plan enumeration:\s+([\d.]+)')
EXEC_PATTERN = re.compile(r'^Execute query:\s+([\d.]+)')
PLAN_COST_PATTERN = re.compile(r'^Plan cost:\s+([\d.eE+\-]+)')

def load_job_queries():
    queries = {}
    for yml_file in sorted(Path(JOB_DIR).glob('q*.yml')):
        # Only take the 'a' version of each query to keep it manageable
        with open(yml_file) as f:
            yml = yaml.safe_load(f)
        query_name = yml_file.stem
        cases = yml.get('cases', {})
        if 'a' in cases:
            queries[f"{query_name}a"] = cases['a'].strip()
        elif cases:
            # Fallback to first case
            first_case = sorted(cases.keys())[0]
            queries[f"{query_name}{first_case}"] = cases[first_case].strip()
    return queries

def transform_query(sql):
    sql_upper = sql.upper()
    from_pos = sql_upper.find('FROM')
    where_pos = sql_upper.find('WHERE')
    if from_pos == -1: return None
    from_clause = sql[from_pos:where_pos] if where_pos != -1 else sql[from_pos:]
    where_clause = sql[where_pos + 5:] if where_pos != -1 else ''
    join_pred_pattern = re.compile(r'(\w+\.\w+)\s*=\s*(\w+\.\w+)')
    join_predicates = []
    for match in join_pred_pattern.finditer(where_clause):
        left, right = match.group(1), match.group(2)
        if left.split('.')[0] != right.split('.')[0]:
            join_predicates.append(f"{left} = {right}")
    if not join_predicates: return None
    where_str = ' AND '.join(join_predicates)
    return f"SELECT * {from_clause.strip()} WHERE {where_str};"

def count_tables(sql):
    m = re.search(r'FROM\s+(.*?)(?:WHERE|$)', sql, re.IGNORECASE | re.DOTALL)
    return len([t.strip() for t in m.group(1).split(',') if t.strip()]) if m else 0

def enqueue_output(out, queue):
    for line in iter(out.readline, ''):
        queue.put(line)
    out.close()

class ShellSession:
    def __init__(self, enumerator, schema_sql):
        self.enumerator = enumerator
        self.schema_sql = schema_sql
        self.proc = None
        self.q = None
        self.t = None
        self.start_process()

    def start_process(self):
        self.close()
        cmd = [SHELL_BINARY, '--benchmark', '--times', '--plan-enumerator', self.enumerator, '--quiet', '--noprompt', '-']
        self.proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        self.q = Queue()
        self.t = Thread(target=enqueue_output, args=(self.proc.stdout, self.q))
        self.t.daemon = True
        self.t.start()
        self.proc.stdin.write(self.schema_sql + "\nSELECT 'READY';\n")
        self.proc.stdin.flush()
        start = time.time()
        while True:
            try:
                line = self.q.get(timeout=1.0)
            except Empty:
                if time.time() - start > 600: break
                continue
            if 'READY' in line: break
            if 'error' in line.lower() or 'exception' in line.lower(): break

    def run_query(self, query_sql, timeout_sec):
        try:
            while not self.q.empty(): self.q.get_nowait()
            self.proc.stdin.write(query_sql + "\n")
            self.proc.stdin.flush()
            metrics = {'opt_time': 0.0, 'enum_time': 0.0, 'exec_time': 0.0, 'error': None}
            start_time = time.time()
            while True:
                if time.time() - start_time > timeout_sec:
                    self.start_process()
                    return {'total_time': None, 'error': f'timeout ({timeout_sec}s)'}
                try:
                    line = self.q.get(timeout=1.0)
                except Empty:
                    if self.proc.poll() is not None:
                        self.start_process()
                        return {'total_time': None, 'error': 'process crashed'}
                    continue
                line = line.strip()
                m = OPT_PATTERN.match(line)
                if m: metrics['opt_time'] = float(m.group(1))
                m = ENUM_PATTERN.match(line)
                if m: metrics['enum_time'] = float(m.group(1))
                m = EXEC_PATTERN.match(line)
                if m: 
                    metrics['exec_time'] = float(m.group(1))
                    total = metrics['opt_time'] + metrics['enum_time'] + metrics['exec_time']
                    return {'total_time': total, 'error': None}
                if 'error' in line.lower() or 'exception' in line.lower():
                    if not 'logic error' in line.lower():
                        return {'total_time': None, 'error': line[:100]}
        except Exception as e:
            self.start_process()
            return {'total_time': None, 'error': str(e)}

    def close(self):
        if self.proc:
            self.proc.terminate()
            self.proc.wait()

def main():
    parser = argparse.ArgumentParser(description='Benchmark Total Time on IMDB JOB')
    parser.add_argument('--timeout', type=int, default=30, help='Timeout per query (default: 30)')
    parser.add_argument('--limit', type=int, default=10, help='Limit number of queries (default: 10)')
    parser.add_argument('--output', type=str, default='job_total_time_benchmark.csv', help='Output CSV')
    args = parser.parse_args()

    if not os.path.isfile(SHELL_BINARY):
        print(f"Error: Shell binary not found at {SHELL_BINARY}")
        sys.exit(1)
    
    with open(SCHEMA_FILE) as f:
        schema_sql = f.read()

    raw_queries = load_job_queries()
    all_queries = {n: (transform_query(s), count_tables(transform_query(s))) for n, s in raw_queries.items() if transform_query(s)}
    selected_names = sorted(all_queries.keys())[:args.limit]
    
    with open(args.output, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['query', 'num_tables', 'enumerator', 'total_time_ms', 'status'])

    print(f"Benchmarking total time: {len(selected_names)} queries, {len(ALL_ENUMERATORS)} enumerators, {args.timeout}s timeout.")
    
    for enumerator in ALL_ENUMERATORS:
        print(f"\nEvaluating: {enumerator}")
        session = ShellSession(enumerator, schema_sql)
        for name in selected_names:
            sql, nt = all_queries[name]
            res = session.run_query(sql, args.timeout)
            status = 'SUCCESS' if not res['error'] else res['error']
            total = res['total_time']
            with open(args.output, 'a', newline='') as f:
                csv.writer(f).writerow([name, nt, enumerator, total, status])
            print(f"  {name:6}: {status} " + (f"({total:.1f}ms)" if total else ""))
        session.close()

    print(f"\nBenchmark complete. Results saved to {args.output}")

if __name__ == '__main__':
    main()
