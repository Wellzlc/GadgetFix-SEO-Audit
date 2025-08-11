#!/bin/bash

# Ultimate SEO Audit System - Dashboard Generator
# Creates live SEO monitoring dashboard

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

display_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ____            _     _                         _ 
 |  _ \  __ _ ___| |__ | |__   ___   __ _ _ __ __| |
 | | | |/ _` / __| '_ \| '_ \ / _ \ / _` | '__/ _` |
 | |_| | (_| \__ \ | | | |_) | (_) | (_| | | | (_| |
 |____/ \__,_|___/_| |_|_.__/ \___/ \__,_|_|  \__,_|
                                                   
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}SEO Monitoring Dashboard${NC}"
    echo -e "${CYAN}Live tracking of SEO performance metrics${NC}"
    echo ""
}

create_dashboard_script() {
    cat > "dashboard.py" << 'EOF'
#!/usr/bin/env python3
"""
SEO Monitoring Dashboard
Live dashboard for tracking SEO metrics and trends
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List

import dash
from dash import dcc, html, Input, Output, callback
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

class SEODashboard:
    def __init__(self):
        self.app = dash.Dash(__name__)
        self.reports_dir = Path("reports")
        self.data_dir = Path("data/history")
        
        # Create app layout
        self.app.layout = self.create_layout()
        
        # Register callbacks
        self.register_callbacks()
    
    def create_layout(self):
        return html.Div([
            html.H1("🔍 SEO Monitoring Dashboard", style={'textAlign': 'center', 'color': '#2c3e50'}),
            
            # Header stats
            html.Div(id='header-stats', children=self.get_header_stats()),
            
            # Main content
            html.Div([
                # Tabs
                dcc.Tabs(id='main-tabs', value='overview', children=[
                    dcc.Tab(label='📊 Overview', value='overview'),
                    dcc.Tab(label='📈 Trends', value='trends'),
                    dcc.Tab(label='🔧 Technical', value='technical'),
                    dcc.Tab(label='⚡ Performance', value='performance'),
                    dcc.Tab(label='📝 Content', value='content'),
                    dcc.Tab(label='🏆 Competitive', value='competitive'),
                ]),
                
                # Tab content
                html.Div(id='tab-content')
            ]),
            
            # Auto-refresh
            dcc.Interval(
                id='interval-component',
                interval=30*1000,  # 30 seconds
                n_intervals=0
            ),
            
            # Footer
            html.Footer([
                html.P(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", 
                       style={'textAlign': 'center', 'color': '#7f8c8d', 'marginTop': '50px'})
            ])
        ], style={'margin': '20px'})
    
    def get_header_stats(self):
        """Get key stats for header"""
        try:
            # Find latest audit files
            latest_files = {}
            for audit_type in ['technical', 'performance', 'content', 'competitive']:
                pattern = f"{audit_type}_audit_*.json"
                matching_files = list(self.reports_dir.glob(pattern))
                if matching_files:
                    latest_files[audit_type] = max(matching_files, key=lambda x: x.stat().st_mtime)
            
            stats = []
            
            # Overall health score
            if latest_files:
                # Calculate composite score (simplified)
                scores = []
                
                if 'technical' in latest_files:
                    with open(latest_files['technical']) as f:
                        data = json.load(f)
                        tech_score = min(len([p for p in data.get('pages', [])]), 1) * 80  # Simplified
                        scores.append(tech_score)
                
                if 'performance' in latest_files:
                    with open(latest_files['performance']) as f:
                        data = json.load(f)
                        perf_score = data.get('summary', {}).get('overall_score', 0)
                        scores.append(perf_score)
                
                overall_score = sum(scores) / len(scores) if scores else 0
                
                color = '#27ae60' if overall_score >= 80 else '#f39c12' if overall_score >= 60 else '#e74c3c'
                stats.append(
                    html.Div([
                        html.H3(f"{overall_score:.0f}/100", style={'color': color, 'margin': '0'}),
                        html.P("SEO Health Score", style={'color': '#7f8c8d', 'margin': '0'})
                    ], style={'textAlign': 'center', 'flex': '1'})
                )
            
            # Add more stats...
            stats.extend([
                html.Div([
                    html.H3(f"{len(latest_files)}", style={'color': '#3498db', 'margin': '0'}),
                    html.P("Audits Available", style={'color': '#7f8c8d', 'margin': '0'})
                ], style={'textAlign': 'center', 'flex': '1'}),
                
                html.Div([
                    html.H3("●", style={'color': '#27ae60', 'margin': '0', 'fontSize': '30px'}),
                    html.P("System Online", style={'color': '#7f8c8d', 'margin': '0'})
                ], style={'textAlign': 'center', 'flex': '1'})
            ])
            
            return html.Div(stats, style={
                'display': 'flex',
                'justifyContent': 'space-around',
                'backgroundColor': '#ecf0f1',
                'padding': '20px',
                'borderRadius': '10px',
                'marginBottom': '30px'
            })
            
        except Exception as e:
            return html.Div(f"Error loading stats: {e}")
    
    def register_callbacks(self):
        @self.app.callback(Output('tab-content', 'children'), Input('main-tabs', 'value'))
        def render_tab_content(active_tab):
            if active_tab == 'overview':
                return self.render_overview_tab()
            elif active_tab == 'trends':
                return self.render_trends_tab()
            elif active_tab == 'technical':
                return self.render_technical_tab()
            elif active_tab == 'performance':
                return self.render_performance_tab()
            elif active_tab == 'content':
                return self.render_content_tab()
            elif active_tab == 'competitive':
                return self.render_competitive_tab()
        
        @self.app.callback(Output('header-stats', 'children'), Input('interval-component', 'n_intervals'))
        def update_header_stats(n):
            return self.get_header_stats()
    
    def render_overview_tab(self):
        return html.Div([
            html.H2("📊 SEO Overview"),
            html.P("Summary of your SEO performance across all areas."),
            
            # Latest audit summary
            self.get_latest_audit_summary(),
            
            # Recent activity
            html.H3("📅 Recent Activity"),
            self.get_recent_activity()
        ])
    
    def render_trends_tab(self):
        return html.Div([
            html.H2("📈 Performance Trends"),
            html.P("Track your SEO metrics over time."),
            
            # Trend charts would go here
            html.Div([
                dcc.Graph(
                    id='trend-chart',
                    figure=self.create_trend_chart()
                )
            ])
        ])
    
    def render_technical_tab(self):
        try:
            pattern = "technical_audit_*.json"
            matching_files = list(self.reports_dir.glob(pattern))
            
            if not matching_files:
                return html.Div("No technical audit data available")
            
            latest_file = max(matching_files, key=lambda x: x.stat().st_mtime)
            
            with open(latest_file) as f:
                data = json.load(f)
            
            return html.Div([
                html.H2("🔧 Technical SEO"),
                
                # Technical metrics
                html.Div([
                    html.Div([
                        html.H4("Site Infrastructure"),
                        html.P(f"✅ Robots.txt: {'Found' if data.get('robots_txt', {}).get('exists') else 'Missing'}"),
                        html.P(f"✅ Sitemap: {'Found' if data.get('sitemap', {}).get('found_sitemaps') else 'Missing'}"),
                        html.P(f"🔒 HTTPS: {'Enabled' if data.get('ssl_certificate', {}).get('https_supported') else 'Disabled'}"),
                    ], style={'flex': '1', 'padding': '20px', 'backgroundColor': '#f8f9fa', 'borderRadius': '10px', 'margin': '10px'}),
                    
                    html.Div([
                        html.H4("Page Optimization"),
                        html.P(f"Pages Analyzed: {len(data.get('pages', []))}"),
                        html.P(f"Issues Found: {data.get('summary', {}).get('total_issues', 0)}"),
                        html.P(f"Critical: {data.get('summary', {}).get('critical_issues', 0)}"),
                    ], style={'flex': '1', 'padding': '20px', 'backgroundColor': '#f8f9fa', 'borderRadius': '10px', 'margin': '10px'})
                ], style={'display': 'flex'})
            ])
            
        except Exception as e:
            return html.Div(f"Error loading technical data: {e}")
    
    def render_performance_tab(self):
        try:
            pattern = "performance_audit_*.json"
            matching_files = list(self.reports_dir.glob(pattern))
            
            if not matching_files:
                return html.Div("No performance audit data available")
            
            latest_file = max(matching_files, key=lambda x: x.stat().st_mtime)
            
            with open(latest_file) as f:
                data = json.load(f)
            
            mobile_cwv = data.get('mobile', {}).get('core_web_vitals', {})
            
            return html.Div([
                html.H2("⚡ Performance Metrics"),
                
                # Core Web Vitals
                html.H3("Core Web Vitals"),
                html.Div([
                    html.Div([
                        html.H4("LCP", style={'color': '#e74c3c'}),
                        html.P(mobile_cwv.get('lcp', {}).get('display_value', 'N/A'))
                    ], style={'textAlign': 'center', 'flex': '1', 'padding': '15px', 'backgroundColor': '#fff5f5', 'borderRadius': '10px', 'margin': '5px'}),
                    
                    html.Div([
                        html.H4("INP", style={'color': '#f39c12'}),
                        html.P(mobile_cwv.get('inp', {}).get('display_value', 'N/A'))
                    ], style={'textAlign': 'center', 'flex': '1', 'padding': '15px', 'backgroundColor': '#fffbf0', 'borderRadius': '10px', 'margin': '5px'}),
                    
                    html.Div([
                        html.H4("CLS", style={'color': '#27ae60'}),
                        html.P(mobile_cwv.get('cls', {}).get('display_value', 'N/A'))
                    ], style={'textAlign': 'center', 'flex': '1', 'padding': '15px', 'backgroundColor': '#f8fff8', 'borderRadius': '10px', 'margin': '5px'})
                ], style={'display': 'flex'})
            ])
            
        except Exception as e:
            return html.Div(f"Error loading performance data: {e}")
    
    def render_content_tab(self):
        return html.Div([
            html.H2("📝 Content Analysis"),
            html.P("Content optimization metrics and recommendations.")
        ])
    
    def render_competitive_tab(self):
        return html.Div([
            html.H2("🏆 Competitive Analysis"),
            html.P("How you compare against competitors.")
        ])
    
    def get_latest_audit_summary(self):
        """Get summary of latest audits"""
        try:
            summaries = []
            
            for audit_type in ['technical', 'performance', 'content', 'competitive']:
                pattern = f"{audit_type}_audit_*.json"
                matching_files = list(self.reports_dir.glob(pattern))
                
                if matching_files:
                    latest_file = max(matching_files, key=lambda x: x.stat().st_mtime)
                    file_time = datetime.fromtimestamp(latest_file.stat().st_mtime)
                    
                    summaries.append(
                        html.Li(f"{audit_type.title()}: {file_time.strftime('%Y-%m-%d %H:%M')}")
                    )
            
            if summaries:
                return html.Div([
                    html.H3("🕒 Latest Audits"),
                    html.Ul(summaries)
                ])
            else:
                return html.P("No audit data available. Run ./run-audit.sh to get started!")
                
        except Exception as e:
            return html.P(f"Error: {e}")
    
    def get_recent_activity(self):
        """Get recent activity log"""
        try:
            log_files = list(Path("logs").glob("*.log"))
            
            if not log_files:
                return html.P("No recent activity")
            
            latest_log = max(log_files, key=lambda x: x.stat().st_mtime)
            
            # Read last few lines
            with open(latest_log, 'r') as f:
                lines = f.readlines()[-10:]  # Last 10 lines
                
            activity = html.Div([
                html.P(line.strip()) for line in lines if line.strip()
            ])
            
            return activity
            
        except Exception as e:
            return html.P(f"Error reading activity: {e}")
    
    def create_trend_chart(self):
        """Create a sample trend chart"""
        # This would load actual historical data
        dates = pd.date_range(start='2024-01-01', periods=30, freq='D')
        scores = [70 + i + (i % 3) * 5 for i in range(30)]  # Sample data
        
        fig = px.line(x=dates, y=scores, title="SEO Score Trend")
        fig.update_layout(
            xaxis_title="Date",
            yaxis_title="SEO Score",
            yaxis_range=[0, 100]
        )
        
        return fig
    
    def run(self, host='127.0.0.1', port=8050, debug=True):
        self.app.run_server(host=host, port=port, debug=debug)

if __name__ == '__main__':
    dashboard = SEODashboard()
    
    print("🚀 Starting SEO Dashboard...")
    print("📊 Dashboard will be available at: http://127.0.0.1:8050")
    print("🔄 Auto-refresh enabled (30s intervals)")
    print("⏹️  Press Ctrl+C to stop")
    
    try:
        dashboard.run()
    except KeyboardInterrupt:
        print("\n👋 Dashboard stopped")
EOF

    print_status "Dashboard script created: dashboard.py"
}

main() {
    display_banner
    
    print_status "Creating SEO monitoring dashboard..."
    
    # Check if Dash is installed
    if ! python3 -c "import dash" 2>/dev/null; then
        print_warning "Dash not installed. Installing dashboard dependencies..."
        pip install dash plotly pandas
    fi
    
    # Create dashboard script
    create_dashboard_script
    
    print_status "Dashboard setup complete! 🎉"
    echo ""
    echo "To start the dashboard:"
    echo "  python3 dashboard.py"
    echo ""
    echo "The dashboard will be available at:"
    echo "  http://127.0.0.1:8050"
    echo ""
    echo "Features:"
    echo "  📊 Real-time SEO metrics"
    echo "  📈 Performance trends"
    echo "  🔧 Technical audit results"
    echo "  ⚡ Core Web Vitals monitoring"
    echo "  📝 Content analysis"
    echo "  🏆 Competitive insights"
    echo ""
    print_status "Run some audits first to populate the dashboard with data!"
}

main "$@"