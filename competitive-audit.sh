#!/bin/bash

# Ultimate SEO Audit System - Competitive Analysis Script
# Wrapper script for competitive analysis with enhanced features

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
   ____                            _   _ _   _              
  / ___|___  _ __ ___  _ __   ___  | |_(_) |_(_)_   _____    
 | |   / _ \| '_ ` _ \| '_ \ / _ \ | __| | __| \ \ / / _ \   
 | |__| (_) | | | | | | |_) |  __/ | |_| | |_| |\ V /  __/   
  \____\___/|_| |_| |_| .__/ \___|  \__|_|\__|_| \_/ \___|   
                      |_|                                    
   _                _           _     
  / \   _ __   __ _| |_   _ ___(_)___ 
 / _ \ | '_ \ / _` | | | | / __| / __|
/ ___ \| | | | (_| | | |_| \__ \ \__ \
/_/   \_\_| |_|\__,_|_|\__, |___/_|___/
                       |___/          
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}Competitive SEO Analysis${NC}"
    echo -e "${CYAN}Analyze competitors and identify opportunities${NC}"
    echo ""
}

show_usage() {
    cat << EOF
Usage: $0 <website_url> <competitor1,competitor2,...>

Performs comprehensive competitive SEO analysis including:
- SERP position tracking
- Content gap analysis  
- Technical SEO comparison
- Performance benchmarking

EXAMPLES:
    $0 https://example.com https://competitor1.com,https://competitor2.com
    $0 example.com competitor1.com,competitor2.com,competitor3.com

PARAMETERS:
    website_url     Your website URL
    competitors     Comma-separated list of competitor URLs

EOF
}

main() {
    display_banner
    
    if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    local website_url="$1"
    local competitors="$2"
    
    # Normalize URLs
    if [[ ! "$website_url" =~ ^https?:// ]]; then
        website_url="https://$website_url"
    fi
    
    print_status "Target website: $website_url"
    print_status "Competitors: $competitors"
    print_status "Starting competitive analysis..."
    
    # Run competitive audit
    if python3 scripts/competitive-audit.py "$website_url" "$competitors"; then
        print_status "Competitive analysis completed successfully! 🎉"
        
        # Generate report
        print_status "Generating competitive analysis report..."
        python3 scripts/generate-report.py --latest
        
        echo ""
        echo "View your competitive analysis results in the reports/ directory"
        echo "Key insights have been saved for strategic planning"
    else
        print_error "Competitive analysis failed"
        exit 1
    fi
}

main "$@"