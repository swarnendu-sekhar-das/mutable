import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

def generate_report(csv_file='job_benchmark_final.csv'):
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found.")
        return

    df = pd.read_csv(csv_file)
    df = df[df['status'] == 'SUCCESS']
    
    # Convert numerical columns
    for col in ['opt_time_ms', 'enum_time_ms', 'exec_time_ms', 'plan_cost', 'num_tables']:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # 1. Total Time Comparison (Opt + Exec)
    df['total_time_ms'] = df['opt_time_ms'] + df['exec_time_ms']
    
    plt.figure(figsize=(12, 8))
    sns.boxplot(x='enumerator', y='total_time_ms', data=df)
    plt.yscale('log')
    plt.title('Total Query Time (Optimization + Execution) Distribution')
    plt.ylabel('Time (ms, log scale)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig('total_time_distribution.png')
    
    # 2. Planning Time vs Query Complexity (Number of Tables)
    plt.figure(figsize=(12, 8))
    sns.lineplot(x='num_tables', y='opt_time_ms', hue='enumerator', data=df, marker='o')
    plt.yscale('log')
    plt.title('Optimization Time Scaling vs Join Complexity')
    plt.xlabel('Number of Tables')
    plt.ylabel('Optimization Time (ms, log scale)')
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    plt.savefig('opt_time_scaling.png')

    # 3. Geometric Mean Performance
    def geo_mean(x):
        return np.exp(np.log(x[x > 0]).mean())

    summary = df.groupby('enumerator')[['opt_time_ms', 'exec_time_ms', 'total_time_ms']].agg(geo_mean)
    summary['success_count'] = df.groupby('enumerator')['status'].count()
    summary = summary.sort_values('total_time_ms')
    
    print("\nBenchmark Summary (Geometric Mean):")
    print(summary)
    summary.to_csv('benchmark_summary.csv')

    # 4. Success Rates
    total_queries = df['query'].nunique()
    success_rates = df.groupby('enumerator')['query'].nunique() / total_queries * 100
    
    plt.figure(figsize=(10, 6))
    success_rates.sort_values().plot(kind='barh', color='skyblue')
    plt.title('Query Success Rates (%) - Completion before 1min Timeout')
    plt.xlabel('Success Rate (%)')
    plt.tight_layout()
    plt.savefig('success_rates.png')

    print("\nPlots generated: total_time_distribution.png, opt_time_scaling.png, success_rates.png")

if __name__ == "__main__":
    generate_report()
