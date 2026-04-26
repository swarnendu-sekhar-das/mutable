#!/usr/bin/env python3
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import os
import argparse

COLORS = {
    'TwoPhaseOptimizer': '#58a6ff',
    'DPccp': '#f78166',
    'GOO': '#7ee787',
    'IKKBZ': '#d2a8ff',
    'LinearizedDP': '#ffa657',
    'TDGOO': '#ff7b72',
    'TDbasic': '#79c0ff',
    'TDMinCutAGaT': '#56d364',
    'HeuristicSearch': '#e3b341',
    'DPsize': '#bc8cff',
    'DPsub': '#f69d50',
    'DPsizeOpt': '#db61a2',
    'DPsubOpt': '#3fb950',
    'DPsizeSub': '#8b949e',
    'PEall': '#da3633',
}

def get_color(enum_name):
    return COLORS.get(enum_name, '#8b949e')

def setup_style():
    plt.rcParams.update({
        'figure.facecolor': '#0d1117',
        'axes.facecolor': '#161b22',
        'axes.edgecolor': '#30363d',
        'axes.labelcolor': '#c9d1d9',
        'text.color': '#c9d1d9',
        'xtick.color': '#8b949e',
        'ytick.color': '#8b949e',
        'grid.color': '#21262d',
        'grid.alpha': 0.6,
        'font.family': 'sans-serif',
        'font.size': 11,
        'axes.titlesize': 14,
        'axes.labelsize': 12,
        'legend.facecolor': '#161b22',
        'legend.edgecolor': '#30363d',
        'savefig.facecolor': '#0d1117',
    })

def generate_report(csv_file, outdir):
    os.makedirs(outdir, exist_ok=True)

    df = pd.read_csv(csv_file)
    
    # Filter to successful runs
    df_ok = df[df['status'] == 'SUCCESS'].copy()
    for col in ['opt_time_ms', 'enum_time_ms', 'exec_time_ms', 'plan_cost', 'num_tables']:
        df_ok[col] = pd.to_numeric(df_ok[col], errors='coerce')
        
    enumerators = sorted(df_ok['enumerator'].unique())
    
    if df_ok.empty:
        print("ERROR: No successful runs found!")
        return

    # 1. Total Execution Time per enumerator (sum of all successfully executed queries that ALL enumerators succeeded on)
    # To compare fairly, we should find the common subset of queries all enumerators solved, OR just show median execution time.
    
    # Geometric mean execution time
    def geo_mean(x):
        x = x[x > 0]
        return np.exp(np.log(x).mean()) if len(x) > 0 else 0

    geo_stats = df_ok.groupby('enumerator').agg(
        geo_exec=('exec_time_ms', geo_mean),
        geo_opt=('opt_time_ms', geo_mean),
        count=('exec_time_ms', 'count')
    ).sort_values('geo_exec')

    fig, ax = plt.subplots(figsize=(14, 7))
    x = range(len(geo_stats))
    bar_colors = [get_color(e) for e in geo_stats.index]

    bars = ax.bar(x, geo_stats['geo_exec'], color=bar_colors, alpha=0.85, edgecolor='#30363d')

    for i, e in enumerate(geo_stats.index):
        if e == 'TwoPhaseOptimizer':
            bars[i].set_edgecolor('#58a6ff')
            bars[i].set_linewidth(2.5)
            bars[i].set_alpha(1.0)

    ax.set_xticks(x)
    ax.set_xticklabels(geo_stats.index, rotation=45, ha='right')
    ax.set_ylabel('Geometric Mean Execution Time (ms)')
    ax.set_title('Geometric Mean Execution Time Across JOB Queries')
    ax.grid(True, axis='y', alpha=0.3)

    for i, (v, e) in enumerate(zip(geo_stats['geo_exec'], geo_stats.index)):
        ax.text(i, v * 1.05, f'{v:.1f}', ha='center', va='bottom', fontsize=8, color='#c9d1d9')

    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '1_geo_mean_exec_time.png'))
    plt.close()
    
    # 2. Total Time = Opt + Enum + Exec
    df_ok['total_time_ms'] = df_ok['opt_time_ms'].fillna(0) + df_ok['exec_time_ms'].fillna(0)
    geo_total_stats = df_ok.groupby('enumerator').agg(
        geo_total=('total_time_ms', geo_mean)
    ).sort_values('geo_total')

    fig, ax = plt.subplots(figsize=(14, 7))
    x = range(len(geo_total_stats))
    bar_colors = [get_color(e) for e in geo_total_stats.index]

    bars = ax.bar(x, geo_total_stats['geo_total'], color=bar_colors, alpha=0.85, edgecolor='#30363d')
    for i, e in enumerate(geo_total_stats.index):
        if e == 'TwoPhaseOptimizer':
            bars[i].set_edgecolor('#58a6ff')
            bars[i].set_linewidth(2.5)

    ax.set_xticks(x)
    ax.set_xticklabels(geo_total_stats.index, rotation=45, ha='right')
    ax.set_ylabel('Geometric Mean Total Time (Opt + Exec, ms)')
    ax.set_title('Geometric Mean Total Time Across JOB Queries')
    ax.grid(True, axis='y', alpha=0.3)
    
    for i, v in enumerate(geo_total_stats['geo_total']):
        ax.text(i, v * 1.05, f'{v:.1f}', ha='center', va='bottom', fontsize=8, color='#c9d1d9')

    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '2_geo_mean_total_time.png'))
    plt.close()

    # 3. Success Rates
    total_q = df['query'].nunique()
    success_rate = (geo_stats['count'] / total_q * 100).sort_values()
    
    fig, ax = plt.subplots(figsize=(12, 7))
    bar_colors = [get_color(e) for e in success_rate.index]
    bars = ax.barh(range(len(success_rate)), success_rate.values, color=bar_colors, alpha=0.85, edgecolor='#30363d')
    
    for i, e in enumerate(success_rate.index):
        if e == 'TwoPhaseOptimizer':
            bars[i].set_edgecolor('#58a6ff')
            bars[i].set_linewidth(2.5)

    ax.set_yticks(range(len(success_rate)))
    ax.set_yticklabels(success_rate.index)
    ax.set_xlabel('Query Success Rate (%)')
    ax.set_title(f'Query Execution Completion Rate (out of {total_q} JOB queries)')
    ax.set_xlim(0, 105)
    ax.grid(True, axis='x', alpha=0.3)

    for i, v in enumerate(success_rate.values):
        ax.text(v + 0.5, i, f'{v:.0f}%', va='center', fontsize=9, color='#c9d1d9')

    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '3_execution_success_rates.png'))
    plt.close()

    print(f"Execution report generated in {outdir}/")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv', default='job_execution_benchmark.csv')
    parser.add_argument('--outdir', default='benchmark_execution_results')
    args = parser.parse_args()
    
    setup_style()
    generate_report(args.csv, args.outdir)
