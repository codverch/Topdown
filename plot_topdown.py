#!/usr/bin/env python3
"""
Script to plot Back-End Bound percentages from Topdown analysis results.
Reads summary files from crono-results and creates a compact bar chart with slimmer bars.
"""
import os
import re
import matplotlib.pyplot as plt
import sys


def extract_backend_bound(summary_file):
    """
    Extract the Back-End Bound percentage from a summary file.
    Args:
        summary_file: Path to the summary file
    Returns:
        float: Back-End Bound percentage, or None if not found
    """
    try:
        with open(summary_file, 'r') as f:
            content = f.read()
        # Look for pattern like "Back-End Bound: 31.4% of Pipeline Slots"
        match = re.search(r'Back-End Bound:\s+([\d.]+)%', content)
        if match:
            return float(match.group(1))
    except Exception as e:
        print(f"Error reading {summary_file}: {e}")
    return None


def get_full_app_name(app):
    """Map short app names to full names for display."""
    name_map = {
        'bfs_gnutella31': 'breadth first search',
        'dfs_gnutella31': 'depth first search',
        'pr_gnutella31': 'pagerank',
        'tc_gnutella31': 'triangle counting',
        'sssp_ego_fb': 'single source shortest path'
    }
    return name_map.get(app, app)


def main():
    # Base directory containing the results
    if len(sys.argv) > 1:
        base_dir = sys.argv[1]
    else:
        base_dir = os.path.expanduser("~/Topdown/crono-results")

    if not os.path.exists(base_dir):
        print(f"Error: Directory {base_dir} not found!")
        print(f"Usage: {sys.argv[0]} [path_to_crono-results]")
        sys.exit(1)

    # Dictionary to store app names and their Back-End Bound percentages
    apps_data = {}

    # Iterate through subdirectories
    for app_dir in sorted(os.listdir(base_dir)):
        app_path = os.path.join(base_dir, app_dir)
        if not os.path.isdir(app_path):
            continue

        # Look for the summary file
        summary_file = os.path.join(app_path, f"{app_dir}_topdown_summary.txt")
        if os.path.exists(summary_file):
            backend_bound = extract_backend_bound(summary_file)
            if backend_bound is not None:
                apps_data[app_dir] = backend_bound
                print(f"Found {app_dir}: {backend_bound}%")

    if not apps_data:
        print("No data found! Check if summary files exist and contain Back-End Bound metrics.")
        sys.exit(1)

    # Sort by app name for consistent ordering
    apps = sorted(apps_data.keys())
    values = [apps_data[app] for app in apps]

    # Calculate average
    average_value = sum(values) / len(values)

    # Add average to the data
    apps.append("Average")
    values.append(average_value)

    # Convert app names to full names
    apps_labels = [get_full_app_name(app) for app in apps[:-1]] + [r'$\mathbf{Average}$']

    # Print summary statistics
    print(f"\nSummary Statistics:")
    print(f"{'App':<35} {'Back-End Bound':>20}")
    print("-" * 60)
    for i, app in enumerate(apps[:-1]):
        display_name = get_full_app_name(app)
        print(f"{display_name:<35} {values[i]:>19.1f}%")
    print("-" * 60)
    print(f"{'Average':<35} {average_value:>19.1f}%")

    # === COMPACT BAR CHART: SLIMMER BARS + REDUCED SPACING ===
    backend_color = '#A72703'  # Purple color
    bar_spacing = 0.1        # Reduced from 0.5 → tighter gaps
    x = [i * bar_spacing for i in range(len(apps))]
    width = 0.05             # Slimmer bars (was 0.35)

    plt.figure(figsize=(16, 8))  # Reduced width for compact layout

    plt.rcParams.update({
        'font.size': 14,
        'font.family': 'serif',
        'mathtext.fontset': 'dejavuserif'
    })

    ax = plt.gca()

    # Grid styling
    plt.grid(True, axis='y', alpha=0.8, linestyle=':', color='black', linewidth=2.0, zorder=0)

    # Create slimmer bars
    bars = plt.bar(x, values, width, alpha=0.9, color=backend_color,
                   edgecolor='black', linewidth=1.2, zorder=3)

    # Add vertical separator between apps and average
    if len(apps) > 1:
        separator_x = (len(apps) - 1.5) * bar_spacing
        plt.axvline(x=separator_x, color='#C41230', linestyle='--',
                    alpha=0.7, linewidth=2.0, zorder=2)

    # X-axis formatting
    ax.set_xticks(x)
    ax.set_xticklabels(apps_labels, rotation=30, ha='right', fontsize=24)
    plt.subplots_adjust(bottom=0.25)  # Padding for rotated labels
    plt.yticks(fontsize=26)
    plt.ylabel('Back-End Bound\n(% of Pipeline Slots)', fontsize=24)

    # Set y-axis range with headroom
    y_max = max(values) + 5
    plt.ylim(0, y_max)

    # Format y-axis as integers only
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{int(x)}'))

    # Keep full box around plot
    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_color('black')
        spine.set_linewidth(1.0)

    plt.tight_layout()

    # Save high-quality versions
    plt.savefig('backend_bound_plot.png', bbox_inches='tight', dpi=300)
    plt.savefig('backend_bound_plot.pdf', bbox_inches='tight', dpi=300)
    plt.savefig('backend_bound_plot.eps', bbox_inches='tight', dpi=300)

    print(f"\nBack-End Bound plots saved as:")
    print(f" - backend_bound_plot.png")
    print(f" - backend_bound_plot.pdf")
    print(f" - backend_bound_plot.eps")

    plt.show()


if __name__ == "__main__":
    main()
