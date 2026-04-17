#!/usr/bin/env python3
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
    'TwoPhaseOptimizer', 'PEall', 'TDMinCutAGaT', 'TDbasic', 'IKKBZ', 
    'TDGOO', 'HeuristicSearch', 'DPsize', 'DPsub', 'LinearizedDP', 'GOO', 
    'DPsubOpt', 'DPsizeOpt', 'DPccp', 'DPsizeSub'
]
TIMEOUT_PER_QUERY = 60  # 1 minute per query as requested
OUTPUT_CSV = 'job_benchmark_final.csv'

# Patterns
OPT_PATTERN = re.compile(r'^Compute the logical query plan:\s+([\d.]+)')
ENUM_PATTERN = re.compile(r'^Plan enumeration:\s+([\d.]+)')
EXEC_PATTERN = re.compile(r'^Execute query:\s+([\d.]+)')
PLAN_COST_PATTERN = re.compile(r'^Plan cost:\s+([\d.eE+\-]+)')

def load_job_queries():
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

class ShellSession:
    def __init__(self, enumerator, schema_sql):
        self.enumerator = enumerator
        self.schema_sql = schema_sql
        self.proc = None
        self.start_process()

    def start_process(self):
        if self.proc:
            self.proc.terminate()
            self.proc.wait()
        cmd = [SHELL_BINARY, '--benchmark', '--times', '--plan-enumerator', self.enumerator, '--quiet', '--noprompt', '-']
        self.proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        
        # Load schema and a marker to know when it's done
        self.proc.stdin.write(self.schema_sql + "\nSELECT 'READY';\n")
        self.proc.stdin.flush()
        
        # Wait for READY (allow up to 10 mins for initial import)
        start = time.time()
        while True:
            line = self.proc.stdout.readline()
            if not line: break
            if 'READY' in line: break
            if 'error' in line.lower(): 
                print(f"  Error during initialization: {line.strip()}")
                break
            if time.time() - start > 600: # 10 min hard timeout for import
                print("  Initialization timed out (10 mins)")
                break

    def run_query(self, query_sql):
        try:
            self.proc.stdin.write(query_sql + "\n")
            self.proc.stdin.flush()
            
            metrics = {'opt_time': None, 'enum_time': None, 'exec_time': None, 'plan_cost': None, 'error': None}
            start_time = time.time()
            
            # Read lines until we get the "Execute query" or "error" or timeout
            while True:
                if time.time() - start_time > TIMEOUT_PER_QUERY:
                    self.start_process() # Restart if timeout
                    return {'opt_time': None, 'enum_time': None, 'exec_time': None, 'plan_cost': None, 'error': 'timeout'}
                
                line = self.proc.stdout.readline()
                if not line: break
                line = line.strip()
                
                m = OPT_PATTERN.match(line)
                if m: metrics['opt_time'] = float(m.group(1))
                m = ENUM_PATTERN.match(line)
                if m: metrics['enum_time'] = float(m.group(1))
                m = EXEC_PATTERN.match(line)
                if m: 
                    metrics['exec_time'] = float(m.group(1))
                    break # Success marker
                m = PLAN_COST_PATTERN.match(line)
                if m: metrics['plan_cost'] = float(m.group(1))
                if 'error' in line.lower():
                    metrics['error'] = line[:100]
                    break
            
            return metrics
        except Exception as e:
            self.start_process()
            return {'opt_time': None, 'enum_time': None, 'exec_time': None, 'plan_cost': None, 'error': str(e)}

    def close(self):
        if self.proc:
            self.proc.terminate()
            self.proc.wait()

def main():
    if not os.path.isfile(SHELL_BINARY):
        print(f"Error: Shell binary not found at {SHELL_BINARY}")
        sys.exit(1)
    
    with open(SCHEMA_FILE) as f:
        schema_sql = f.read()

    raw_queries = load_job_queries()
    queries = {n: (transform_query(s), count_tables(transform_query(s))) for n, s in raw_queries.items() if transform_query(s)}
    
    print(f"Starting benchmark: {len(queries)} queries, {len(ENUMERATORS)} enumerators, {TIMEOUT_PER_QUERY}s timeout.")
    
    with open(OUTPUT_CSV, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['query', 'num_tables', 'enumerator', 'opt_time_ms', 'enum_time_ms', 'exec_time_ms', 'plan_cost', 'status'])

    for enumerator in ENUMERATORS:
        print(f"\nEvaluating: {enumerator}")
        session = ShellSession(enumerator, schema_sql)
        for name in sorted(queries.keys()):
            sql, nt = queries[name]
            metrics = session.run_query(sql)
            status = 'SUCCESS' if not metrics['error'] else metrics['error']
            
            row = [name, nt, enumerator, metrics['opt_time'], metrics['enum_time'], metrics['exec_time'], metrics['plan_cost'], status]
            with open(OUTPUT_CSV, 'a', newline='') as f:
                csv.writer(f).writerow(row)
            
            msg = f"  {name:6}: {status}"
            if status == 'SUCCESS':
                msg += f" (opt={metrics['opt_time']:.1f}ms, cost={metrics.get('plan_cost', 'N/A')})"
            print(msg)
        session.close()

    print(f"\nBenchmark complete. Results saved to {OUTPUT_CSV}")

if __name__ == '__main__':
    main()
