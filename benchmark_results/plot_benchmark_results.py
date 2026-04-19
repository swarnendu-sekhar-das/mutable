#!/usr/bin/env python3
"""
Generate plots for plan enumerator benchmark results.

This script visualizes the performance of various plan enumerators including:
- DPccp, DPsubOpt, TDMinCutAGaT (traditional dynamic programming)
- TwoPhaseOptimizer (Two-Phase Optimization combining Iterative Improvement and Simulated Annealing)
- TDbasic, DPsizeOpt, DPsizeSub, DPsub (other DP variants)

The plots compare execution time across different query topologies (star, chain, cycle, clique)
and varying numbers of relations.
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 12

# Read the benchmark results
df = pd.read_csv('plan_enumerator_results.csv')

# Extract plan enumerator name from name column
df['planner'] = df['name'].str.extract(r'single core, (.+)\)')

# Calculate mean time for each planner, topology, and size
summary = df.groupby(['experiment', 'planner', 'case'])['time'].mean().reset_index()
summary['case'] = summary['case'].astype(int)

# Get unique planners and topologies
planners = summary['planner'].unique()
topologies = summary['experiment'].unique()

# Create a plot for each topology
for topology in topologies:
    topology_data = summary[summary['experiment'] == topology]

    fig, ax = plt.subplots(figsize=(14, 8))

    # Plot each planner
    for planner in planners:
        planner_data = topology_data[topology_data['planner'] == planner]
        if len(planner_data) > 0:
            ax.plot(planner_data['case'], planner_data['time'],
                   marker='o', label=planner, linewidth=2, markersize=6)

    ax.set_xlabel('Number of Relations', fontsize=14, fontweight='bold')
    ax.set_ylabel('Execution Time (ms)', fontsize=14, fontweight='bold')
    ax.set_title(f'Plan Enumerator Performance - {topology.capitalize()} Topology',
                 fontsize=16, fontweight='bold')
    ax.set_yscale('log')
    ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=10)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(f'{topology}_performance.png', dpi=300, bbox_inches='tight')
    plt.close()

    print(f"Generated plot for {topology}")

# Create a combined plot with all topologies in subplots
fig, axes = plt.subplots(2, 2, figsize=(16, 12))
axes = axes.flatten()

for idx, topology in enumerate(topologies):
    topology_data = summary[summary['experiment'] == topology]
    ax = axes[idx]

    for planner in planners:
        planner_data = topology_data[topology_data['planner'] == planner]
        if len(planner_data) > 0:
            ax.plot(planner_data['case'], planner_data['time'],
                   marker='o', label=planner, linewidth=2, markersize=5)

    ax.set_xlabel('Number of Relations', fontsize=11, fontweight='bold')
    ax.set_ylabel('Time (ms)', fontsize=11, fontweight='bold')
    ax.set_title(f'{topology.capitalize()}', fontsize=13, fontweight='bold')
    ax.set_yscale('log')
    ax.grid(True, alpha=0.3)
    if idx == 0:
        ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)

plt.tight_layout()
plt.savefig('all_topologies_performance.png', dpi=300, bbox_inches='tight')
plt.close()

print("Generated combined plot for all topologies")

# Create a comparison plot focusing on TwoPhaseOptimizer vs others
fig, axes = plt.subplots(2, 2, figsize=(16, 12))
axes = axes.flatten()

for idx, topology in enumerate(topologies):
    topology_data = summary[summary['experiment'] == topology]
    ax = axes[idx]

    # Plot TwoPhaseOptimizer prominently
    two_phase_data = topology_data[topology_data['planner'] == 'TwoPhaseOptimizer']
    if len(two_phase_data) > 0:
        ax.plot(two_phase_data['case'], two_phase_data['time'],
               marker='o', label='TwoPhaseOptimizer', linewidth=3,
               markersize=8, color='red', alpha=0.8)

    # Plot other planners in gray
    other_planners = [p for p in planners if p != 'TwoPhaseOptimizer']
    for planner in other_planners:
        planner_data = topology_data[topology_data['planner'] == planner]
        if len(planner_data) > 0:
            ax.plot(planner_data['case'], planner_data['time'],
                   marker='o', label=planner, linewidth=1.5,
                   markersize=4, color='gray', alpha=0.5)

    ax.set_xlabel('Number of Relations', fontsize=11, fontweight='bold')
    ax.set_ylabel('Time (ms)', fontsize=11, fontweight='bold')
    ax.set_title(f'{topology.capitalize()}', fontsize=13, fontweight='bold')
    ax.set_yscale('log')
    ax.grid(True, alpha=0.3)
    if idx == 0:
        ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)

plt.tight_layout()
plt.savefig('twophase_vs_others.png', dpi=300, bbox_inches='tight')
plt.close()

print("Generated TwoPhaseOptimizer comparison plot")

# Create a bar chart comparing average performance across all topologies
avg_performance = summary.groupby('planner')['time'].mean().sort_values(ascending=True)

fig, ax = plt.subplots(figsize=(12, 8))
bars = ax.bar(range(len(avg_performance)), avg_performance.values,
              color='steelblue', edgecolor='black', linewidth=1.5)
ax.set_xlabel('Plan Enumerator', fontsize=14, fontweight='bold')
ax.set_ylabel('Average Execution Time (ms)', fontsize=14, fontweight='bold')
ax.set_title('Average Performance Across All Topologies', fontsize=16, fontweight='bold')
ax.set_xticks(range(len(avg_performance)))
ax.set_xticklabels(avg_performance.index, rotation=45, ha='right')
ax.set_yscale('log')
ax.grid(True, alpha=0.3, axis='y')

# Add value labels on bars
for i, (idx, row) in enumerate(avg_performance.items()):
    ax.text(i, row, f'{row:.2f}', ha='center', va='bottom', fontsize=9)

plt.tight_layout()
plt.savefig('average_performance.png', dpi=300, bbox_inches='tight')
plt.close()

print("Generated average performance bar chart")

print("\nAll plots generated successfully!")
print("Generated files:")
print("- chain_performance.png")
print("- clique_performance.png")
print("- cycle_performance.png")
print("- star_performance.png")
print("- all_topologies_performance.png")
print("- twophase_vs_others.png")
print("- average_performance.png")
