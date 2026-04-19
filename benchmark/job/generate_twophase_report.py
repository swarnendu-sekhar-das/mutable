#!/usr/bin/env python3
"""
Generate a comprehensive visual report from TwoPhaseOptimizer JOB benchmark results.

Produces:
  1. Optimization time comparison (bar chart)
  2. Enumeration time scaling vs join complexity (line)
  3. Plan cost comparison (scatter)
  4. Success/timeout rates (horizontal bar)
  5. TwoPhaseOptimizer speedup ratio vs each enumerator (heatmap)
  6. Per-query detailed comparison table
  7. Summary statistics CSV

Usage:
    python3 benchmark/job/generate_twophase_report.py [--csv FILE] [--outdir DIR]
"""

import pandas as pd
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import os
import sys
import argparse
from datetime import datetime


def setup_style():
    """Configure matplotlib for publication-quality plots."""
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
        'legend.fontsize': 9,
        'legend.facecolor': '#161b22',
        'legend.edgecolor': '#30363d',
        'savefig.facecolor': '#0d1117',
        'savefig.dpi': 150,
        'savefig.bbox': 'tight',
    })


# Color palette (GitHub dark theme inspired)
COLORS = {
    'TwoPhaseOptimizer': '#58a6ff',  # Bright blue - our star
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


def generate_report(csv_file, outdir):
    """Generate all report artifacts."""
    os.makedirs(outdir, exist_ok=True)

    df = pd.read_csv(csv_file)
    print(f"Loaded {len(df)} rows from {csv_file}")
    print(f"Enumerators: {sorted(df['enumerator'].unique())}")
    print(f"Queries: {df['query'].nunique()}")

    # Filter to successful runs
    df_ok = df[df['status'] == 'SUCCESS'].copy()
    for col in ['opt_time_ms', 'enum_time_ms', 'plan_cost', 'num_tables']:
        df_ok[col] = pd.to_numeric(df_ok[col], errors='coerce')

    if df_ok.empty:
        print("ERROR: No successful runs found!")
        return

    # Compute median across runs for each (query, enumerator) pair
    med = df_ok.groupby(['query', 'num_tables', 'enumerator']).agg({
        'opt_time_ms': 'median',
        'enum_time_ms': 'median',
        'plan_cost': 'median'
    }).reset_index()

    enumerators = sorted(med['enumerator'].unique())

    # ──────────────────────────────────────────────────
    # 1. Optimization Time distribution (box plot)
    # ──────────────────────────────────────────────────
    fig, ax = plt.subplots(figsize=(14, 7))
    box_data = [med[med['enumerator'] == e]['opt_time_ms'].dropna().values for e in enumerators]
    colors = [get_color(e) for e in enumerators]

    bp = ax.boxplot(box_data, labels=enumerators, patch_artist=True,
                    showfliers=True, flierprops={'marker': '.', 'markersize': 3, 'alpha': 0.4})
    for patch, color in zip(bp['boxes'], colors):
        patch.set_facecolor(color)
        patch.set_alpha(0.7)
    for element in ['whiskers', 'caps', 'medians']:
        for item in bp[element]:
            item.set_color('#c9d1d9')

    ax.set_yscale('log')
    ax.set_ylabel('Optimization Time (ms, log scale)')
    ax.set_title('JOB Optimization Time Distribution by Enumerator')
    ax.tick_params(axis='x', rotation=45)
    ax.grid(True, axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '1_opt_time_distribution.png'))
    plt.close()
    print("  ✓ 1_opt_time_distribution.png")

    # ──────────────────────────────────────────────────
    # 2. Enumeration time scaling vs join complexity
    # ──────────────────────────────────────────────────
    fig, ax = plt.subplots(figsize=(14, 7))
    for e in enumerators:
        edf = med[med['enumerator'] == e].sort_values('num_tables')
        if edf.empty:
            continue
        grouped = edf.groupby('num_tables')['enum_time_ms'].median().reset_index()
        ax.plot(grouped['num_tables'], grouped['enum_time_ms'],
                marker='o', markersize=5, label=e, color=get_color(e),
                linewidth=2 if e == 'TwoPhaseOptimizer' else 1.2,
                alpha=1.0 if e == 'TwoPhaseOptimizer' else 0.6,
                zorder=10 if e == 'TwoPhaseOptimizer' else 5)

    ax.set_yscale('log')
    ax.set_xlabel('Number of Tables (Join Complexity)')
    ax.set_ylabel('Enumeration Time (ms, log scale)')
    ax.set_title('Plan Enumeration Time Scaling with Join Complexity')
    ax.legend(bbox_to_anchor=(1.02, 1), loc='upper left', framealpha=0.8)
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '2_enum_time_scaling.png'))
    plt.close()
    print("  ✓ 2_enum_time_scaling.png")

    # ──────────────────────────────────────────────────
    # 3. Geometric mean optimization time (bar chart)
    # ──────────────────────────────────────────────────
    def geo_mean(x):
        x = x[x > 0]
        return np.exp(np.log(x).mean()) if len(x) > 0 else 0

    geo_stats = med.groupby('enumerator').agg(
        geo_opt=('opt_time_ms', geo_mean),
        geo_enum=('enum_time_ms', geo_mean),
        count=('opt_time_ms', 'count')
    ).sort_values('geo_opt')

    fig, ax = plt.subplots(figsize=(14, 7))
    x = range(len(geo_stats))
    bar_colors = [get_color(e) for e in geo_stats.index]

    bars = ax.bar(x, geo_stats['geo_opt'], color=bar_colors, alpha=0.85,
                  edgecolor='#30363d', linewidth=0.5)

    # Highlight TwoPhaseOptimizer bar
    for i, e in enumerate(geo_stats.index):
        if e == 'TwoPhaseOptimizer':
            bars[i].set_edgecolor('#58a6ff')
            bars[i].set_linewidth(2.5)
            bars[i].set_alpha(1.0)

    ax.set_xticks(x)
    ax.set_xticklabels(geo_stats.index, rotation=45, ha='right')
    ax.set_ylabel('Geometric Mean Optimization Time (ms)')
    ax.set_title('Geometric Mean Optimization Time Across JOB Queries')
    ax.grid(True, axis='y', alpha=0.3)

    # Add value labels on bars
    for i, (v, e) in enumerate(zip(geo_stats['geo_opt'], geo_stats.index)):
        ax.text(i, v * 1.05, f'{v:.1f}', ha='center', va='bottom', fontsize=8,
                color='#c9d1d9')

    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '3_geo_mean_opt_time.png'))
    plt.close()
    print("  ✓ 3_geo_mean_opt_time.png")

    # ──────────────────────────────────────────────────
    # 4. Plan cost comparison (TwoPhaseOptimizer vs DPccp)
    # ──────────────────────────────────────────────────
    tpo_costs = med[med['enumerator'] == 'TwoPhaseOptimizer'][['query', 'plan_cost', 'num_tables']].rename(
        columns={'plan_cost': 'tpo_cost'})
    dpccp_costs = med[med['enumerator'] == 'DPccp'][['query', 'plan_cost']].rename(
        columns={'plan_cost': 'dpccp_cost'})

    if not tpo_costs.empty and not dpccp_costs.empty:
        cost_compare = pd.merge(tpo_costs, dpccp_costs, on='query', how='inner')
        cost_compare = cost_compare.dropna(subset=['tpo_cost', 'dpccp_cost'])

        if not cost_compare.empty:
            fig, ax = plt.subplots(figsize=(10, 10))

            max_cost = max(cost_compare['tpo_cost'].max(), cost_compare['dpccp_cost'].max()) * 1.2
            min_cost = min(cost_compare[cost_compare['tpo_cost'] > 0]['tpo_cost'].min(),
                           cost_compare[cost_compare['dpccp_cost'] > 0]['dpccp_cost'].min()) * 0.8

            ax.plot([min_cost, max_cost], [min_cost, max_cost], '--', color='#484f58',
                    linewidth=1, label='Equal cost line')

            scatter = ax.scatter(cost_compare['dpccp_cost'], cost_compare['tpo_cost'],
                                 c=cost_compare['num_tables'], cmap='plasma',
                                 alpha=0.7, s=50, edgecolors='#30363d', linewidth=0.5)

            cbar = plt.colorbar(scatter, ax=ax, label='Number of Tables')
            cbar.ax.yaxis.label.set_color('#c9d1d9')
            cbar.ax.tick_params(colors='#8b949e')

            ax.set_xscale('log')
            ax.set_yscale('log')
            ax.set_xlabel('DPccp Plan Cost')
            ax.set_ylabel('TwoPhaseOptimizer Plan Cost')
            ax.set_title('Plan Cost: TwoPhaseOptimizer vs DPccp\n(points below line = 2PO found better plan)')
            ax.legend()
            ax.grid(True, alpha=0.3)
            ax.set_aspect('equal')

            plt.tight_layout()
            plt.savefig(os.path.join(outdir, '4_plan_cost_comparison.png'))
            plt.close()
            print("  ✓ 4_plan_cost_comparison.png")

    # ──────────────────────────────────────────────────
    # 5. Success / Timeout / Error rates
    # ──────────────────────────────────────────────────
    total_q = df['query'].nunique()
    status_counts = df.groupby(['enumerator', 'status']).size().unstack(fill_value=0)

    fig, ax = plt.subplots(figsize=(12, 7))

    success_col = 'SUCCESS' if 'SUCCESS' in status_counts.columns else None
    if success_col:
        # Compute success rate per enumerator (collapse multiple runs)
        success_per_enum = df[df['status'] == 'SUCCESS'].groupby('enumerator')['query'].nunique()
        success_rate = (success_per_enum / total_q * 100).sort_values()

        bar_colors = [get_color(e) for e in success_rate.index]
        bars = ax.barh(range(len(success_rate)), success_rate.values,
                       color=bar_colors, alpha=0.85, edgecolor='#30363d')

        for i, e in enumerate(success_rate.index):
            if e == 'TwoPhaseOptimizer':
                bars[i].set_edgecolor('#58a6ff')
                bars[i].set_linewidth(2.5)

        ax.set_yticks(range(len(success_rate)))
        ax.set_yticklabels(success_rate.index)
        ax.set_xlabel('Query Success Rate (%)')
        ax.set_title(f'Query Completion Rate (out of {total_q} JOB queries)')
        ax.set_xlim(0, 105)
        ax.grid(True, axis='x', alpha=0.3)

        # Add percentage labels
        for i, v in enumerate(success_rate.values):
            ax.text(v + 0.5, i, f'{v:.0f}%', va='center', fontsize=9, color='#c9d1d9')

    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '5_success_rates.png'))
    plt.close()
    print("  ✓ 5_success_rates.png")

    # ──────────────────────────────────────────────────
    # 6. Speedup heatmap: TwoPhaseOptimizer vs others
    # ──────────────────────────────────────────────────
    tpo_times = med[med['enumerator'] == 'TwoPhaseOptimizer'][['query', 'opt_time_ms']].rename(
        columns={'opt_time_ms': 'tpo_time'})

    if not tpo_times.empty:
        other_enums = [e for e in enumerators if e != 'TwoPhaseOptimizer']
        speedup_data = {}

        for e in other_enums:
            e_times = med[med['enumerator'] == e][['query', 'opt_time_ms']].rename(
                columns={'opt_time_ms': 'other_time'})
            merged = pd.merge(tpo_times, e_times, on='query', how='inner')
            merged = merged[(merged['tpo_time'] > 0) & (merged['other_time'] > 0)]
            if not merged.empty:
                # Speedup > 1 means 2PO is faster; < 1 means 2PO is slower
                speedup_data[e] = (merged['other_time'] / merged['tpo_time']).median()

        if speedup_data:
            fig, ax = plt.subplots(figsize=(10, 6))
            sorted_speedups = sorted(speedup_data.items(), key=lambda x: x[1], reverse=True)
            names = [s[0] for s in sorted_speedups]
            values = [s[1] for s in sorted_speedups]

            bar_colors = ['#7ee787' if v > 1 else '#f85149' for v in values]
            bars = ax.barh(range(len(names)), values, color=bar_colors, alpha=0.85,
                           edgecolor='#30363d')

            ax.axvline(x=1.0, color='#ffa657', linewidth=2, linestyle='--',
                       label='Equal speed')
            ax.set_yticks(range(len(names)))
            ax.set_yticklabels(names)
            ax.set_xlabel('Median Speedup Ratio (> 1 = TwoPhaseOptimizer is faster)')
            ax.set_title('TwoPhaseOptimizer Speedup vs Other Enumerators')
            ax.legend(loc='lower right')
            ax.grid(True, axis='x', alpha=0.3)

            for i, v in enumerate(values):
                ax.text(v + 0.02, i, f'{v:.2f}x', va='center', fontsize=9, color='#c9d1d9')

            plt.tight_layout()
            plt.savefig(os.path.join(outdir, '6_speedup_ratio.png'))
            plt.close()
            print("  ✓ 6_speedup_ratio.png")

    # ──────────────────────────────────────────────────
    # 7. Per-table-count average times (grouped bar)
    # ──────────────────────────────────────────────────
    fig, ax = plt.subplots(figsize=(14, 7))

    table_counts = sorted(med['num_tables'].unique())
    n_enums = len(enumerators)
    bar_width = 0.7 / n_enums

    for i, e in enumerate(enumerators):
        edf = med[med['enumerator'] == e]
        means = [edf[edf['num_tables'] == tc]['opt_time_ms'].median() for tc in table_counts]
        positions = [tc + (i - n_enums / 2) * bar_width for tc in table_counts]
        ax.bar(positions, means, width=bar_width, label=e, color=get_color(e), alpha=0.8)

    ax.set_yscale('log')
    ax.set_xlabel('Number of Tables')
    ax.set_ylabel('Median Optimization Time (ms, log scale)')
    ax.set_title('Optimization Time by Table Count')
    ax.set_xticks(table_counts)
    ax.legend(bbox_to_anchor=(1.02, 1), loc='upper left', framealpha=0.8)
    ax.grid(True, axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(outdir, '7_opt_by_table_count.png'))
    plt.close()
    print("  ✓ 7_opt_by_table_count.png")

    # ──────────────────────────────────────────────────
    # 8. Summary statistics CSV
    # ──────────────────────────────────────────────────
    summary = med.groupby('enumerator').agg(
        queries_completed=('query', 'nunique'),
        median_opt_ms=('opt_time_ms', 'median'),
        mean_opt_ms=('opt_time_ms', 'mean'),
        geo_mean_opt_ms=('opt_time_ms', geo_mean),
        p95_opt_ms=('opt_time_ms', lambda x: x.quantile(0.95)),
        max_opt_ms=('opt_time_ms', 'max'),
        median_enum_ms=('enum_time_ms', 'median'),
        geo_mean_enum_ms=('enum_time_ms', geo_mean),
        median_plan_cost=('plan_cost', 'median'),
    ).round(3)

    summary_path = os.path.join(outdir, 'benchmark_summary.csv')
    summary.to_csv(summary_path)
    print(f"  ✓ benchmark_summary.csv")

    # Print summary table
    print(f"\n{'=' * 100}")
    print("  BENCHMARK SUMMARY (medians across queries)")
    print(f"{'=' * 100}")
    print(summary.to_string())
    print(f"\nAll outputs saved to: {outdir}/")


def main():
    parser = argparse.ArgumentParser(description='Generate TwoPhaseOptimizer JOB benchmark report')
    parser.add_argument('--csv', type=str, default='job_twophase_benchmark.csv',
                        help='Input CSV file')
    parser.add_argument('--outdir', type=str, default='benchmark_results',
                        help='Output directory for plots and summary')
    args = parser.parse_args()

    if not os.path.isfile(args.csv):
        print(f"ERROR: CSV file not found: {args.csv}")
        print("Run the benchmark first: python3 benchmark/job/benchmark_twophase_job.py")
        sys.exit(1)

    setup_style()
    generate_report(args.csv, args.outdir)


if __name__ == '__main__':
    main()
