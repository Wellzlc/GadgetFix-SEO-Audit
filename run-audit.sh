#!/bin/bash

# Ultimate SEO Audit System - Main Execution Script
# Run comprehensive SEO audit with all modules

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

# Display banner
display_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
   _____ ______ ____     ___            _____ __     _____           __
  / ___// ____/ __ \   /   |  __  __   / __(_) /_   / ___/__  _____ / /____  ____ ___
  \__ \/ __/ / / / /  / /| | / / / /  / /_/ / __/   \__ \/ / / / __ / __ \ \/ __ `__ \
 ___/ / /___/ /_/ /  / ___ |/ /_/ /  / __/ / /_    ___/ / /_/ / /_/ / / / /  / / / / /
/____/_____/\____/  /_/  |_|\__,_/  /_/ /_/\__/   /____/\__, /\__,_/_/ /_/__/_/ /_/ /_/
                                                        /____/                      
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}Ultimate Terminal-Based SEO Audit System${NC}"
    echo -e "${CYAN}Comprehensive SEO analysis with actionable insights${NC}"
    echo ""
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <website_url> [competitors]

OPTIONS:
    -h, --help              Show this help message
    -q, --quick             Run quick audit (technical + performance only)
    -t, --technical         Run technical audit only
    -p, --performance       Run performance audit only
    -c, --content           Run content audit only
    -C, --competitive       Run competitive audit only
    -r, --report-only       Generate report from existing data only
    -v, --verbose           Enable verbose output
    --no-report             Skip report generation
    --competitors <urls>    Comma-separated competitor URLs

EXAMPLES:
    $0 https://example.com
    $0 --quick https://example.com
    $0 --competitive https://example.com --competitors "https://competitor1.com,https://competitor2.com"
    $0 --technical https://example.com

WEBSITE_URL:
    Full URL of the website to audit (e.g., https://example.com)

COMPETITORS:
    Optional comma-separated list of competitor URLs for competitive analysis

EOF
}

# Parse command line arguments
parse_arguments() {
    AUDIT_TYPE="comprehensive"
    WEBSITE_URL=""
    COMPETITORS=""
    VERBOSE=false
    GENERATE_REPORT=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -q|--quick)
                AUDIT_TYPE="quick"
                shift
                ;;
            -t|--technical)
                AUDIT_TYPE="technical"
                shift
                ;;
            -p|--performance)
                AUDIT_TYPE="performance"
                shift
                ;;
            -c|--content)
                AUDIT_TYPE="content"
                shift
                ;;
            -C|--competitive)
                AUDIT_TYPE="competitive"
                shift
                ;;
            -r|--report-only)
                AUDIT_TYPE="report"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-report)
                GENERATE_REPORT=false
                shift
                ;;
            --competitors)
                COMPETITORS="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$WEBSITE_URL" ]; then
                    WEBSITE_URL="$1"
                elif [ -z "$COMPETITORS" ]; then
                    COMPETITORS="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [ "$AUDIT_TYPE" != "report" ] && [ -z "$WEBSITE_URL" ]; then
        print_error "Website URL is required"
        show_usage
        exit 1
    fi
    
    if [ "$AUDIT_TYPE" = "competitive" ] && [ -z "$COMPETITORS" ]; then
        print_error "Competitors are required for competitive audit"
        show_usage
        exit 1
    fi
    
    # Validate URL format
    if [ -n "$WEBSITE_URL" ] && [[ ! "$WEBSITE_URL" =~ ^https?:// ]]; then
        WEBSITE_URL="https://$WEBSITE_URL"
        print_warning "Added https:// prefix to URL: $WEBSITE_URL"
    fi
}

# Check system requirements
check_requirements() {
    print_section "CHECKING SYSTEM REQUIREMENTS"
    
    local missing_deps=()
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    fi
    
    # Check required Python packages
    if ! python3 -c "import requests, bs4, pandas, nltk" 2>/dev/null; then
        print_warning "Some Python packages are missing. Run setup.sh to install dependencies."
    fi
    
    # Check Lighthouse
    if ! command -v lighthouse &> /dev/null; then
        print_warning "Lighthouse not found. Install with: npm install -g lighthouse"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please run scripts/setup.sh to install requirements"
        exit 1
    fi
    
    print_status "System requirements check passed ✅"
}

# Setup environment
setup_environment() {
    print_section "SETTING UP ENVIRONMENT"
    
    # Create necessary directories
    mkdir -p {reports,data,logs,config}
    
    # Activate Python virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        print_status "Activating Python virtual environment..."
        source venv/bin/activate
    elif [ -f "venv/Scripts/activate" ]; then
        print_status "Activating Python virtual environment..."
        source venv/Scripts/activate
    fi
    
    # Set environment variables
    export PYTHONPATH="${PYTHONPATH}:$(pwd)"
    
    # Setup logging
    LOG_FILE="logs/audit_$(date +%Y%m%d_%H%M%S).log"
    
    if [ "$VERBOSE" = true ]; then
        exec 1> >(tee -a "$LOG_FILE")
        exec 2>&1
    else
        exec 1> >(tee -a "$LOG_FILE" >/dev/null)
        exec 2>&1
    fi
    
    print_status "Environment setup complete ✅"
    print_status "Log file: $LOG_FILE"
}

# Run individual audit modules
run_technical_audit() {
    print_section "TECHNICAL SEO AUDIT"
    print_status "Analyzing technical SEO factors..."
    
    if python3 scripts/technical-audit.py "$WEBSITE_URL"; then
        print_status "Technical audit completed successfully ✅"
        return 0
    else
        print_error "Technical audit failed ❌"
        return 1
    fi
}

run_performance_audit() {
    print_section "PERFORMANCE AUDIT"
    print_status "Analyzing performance and Core Web Vitals..."
    
    if python3 scripts/performance-audit.py "$WEBSITE_URL"; then
        print_status "Performance audit completed successfully ✅"
        return 0
    else
        print_error "Performance audit failed ❌"
        return 1
    fi
}

run_content_audit() {
    print_section "CONTENT SEO AUDIT"
    print_status "Analyzing content optimization..."
    
    if python3 scripts/content-audit.py "$WEBSITE_URL"; then
        print_status "Content audit completed successfully ✅"
        return 0
    else
        print_error "Content audit failed ❌"
        return 1
    fi
}

run_competitive_audit() {
    print_section "COMPETITIVE ANALYSIS"
    print_status "Analyzing competitive landscape..."
    
    if python3 scripts/competitive-audit.py "$WEBSITE_URL" "$COMPETITORS"; then
        print_status "Competitive audit completed successfully ✅"
        return 0
    else
        print_error "Competitive audit failed ❌"
        return 1
    fi
}

# Generate comprehensive report
generate_report() {
    print_section "GENERATING REPORT"
    print_status "Creating comprehensive SEO audit report..."
    
    if python3 scripts/generate-report.py --latest; then
        print_status "Report generation completed successfully ✅"
        
        # Find the latest report files
        if ls reports/seo_audit_report_*.html 1> /dev/null 2>&1; then
            LATEST_HTML=$(ls -t reports/seo_audit_report_*.html | head -1)
            print_status "HTML report: $LATEST_HTML"
        fi
        
        if ls reports/executive_summary_*.txt 1> /dev/null 2>&1; then
            LATEST_SUMMARY=$(ls -t reports/executive_summary_*.txt | head -1)
            print_status "Executive summary: $LATEST_SUMMARY"
        fi
        
        return 0
    else
        print_error "Report generation failed ❌"
        return 1
    fi
}

# Display audit summary
display_summary() {
    print_section "AUDIT SUMMARY"
    
    # Find and display executive summary
    if ls reports/executive_summary_*.txt 1> /dev/null 2>&1; then
        LATEST_SUMMARY=$(ls -t reports/executive_summary_*.txt | head -1)
        echo ""
        cat "$LATEST_SUMMARY"
        echo ""
    else
        print_warning "Executive summary not found"
    fi
    
    print_status "Audit completed successfully! 🎉"
    echo ""
    echo "Next steps:"
    echo "1. Review the detailed HTML report"
    echo "2. Address critical issues first"
    echo "3. Implement quick wins for immediate improvements"
    echo "4. Monitor progress with regular audits"
    echo ""
    echo "Report files:"
    ls -la reports/ | grep "$(date +%Y%m%d)" || ls -la reports/ | tail -5
}

# Main execution function
main() {
    local start_time=$(date +%s)
    local success=true
    local audit_count=0
    
    display_banner
    
    parse_arguments "$@"
    check_requirements
    setup_environment
    
    print_section "STARTING SEO AUDIT"
    print_status "Website: $WEBSITE_URL"
    print_status "Audit type: $AUDIT_TYPE"
    print_status "Timestamp: $(date)"
    
    # Run audits based on type
    case "$AUDIT_TYPE" in
        "comprehensive")
            print_status "Running comprehensive audit (all modules)..."
            run_technical_audit && ((audit_count++))
            run_performance_audit && ((audit_count++))
            run_content_audit && ((audit_count++))
            if [ -n "$COMPETITORS" ]; then
                run_competitive_audit && ((audit_count++))
            fi
            ;;
        "quick")
            print_status "Running quick audit (technical + performance)..."
            run_technical_audit && ((audit_count++))
            run_performance_audit && ((audit_count++))
            ;;
        "technical")
            run_technical_audit && ((audit_count++))
            ;;
        "performance")
            run_performance_audit && ((audit_count++))
            ;;
        "content")
            run_content_audit && ((audit_count++))
            ;;
        "competitive")
            run_competitive_audit && ((audit_count++))
            ;;
        "report")
            print_status "Generating report from existing data..."
            ;;
        *)
            print_error "Unknown audit type: $AUDIT_TYPE"
            exit 1
            ;;
    esac
    
    # Generate report if requested
    if [ "$GENERATE_REPORT" = true ]; then
        if ! generate_report; then
            success=false
        fi
    fi
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_section "EXECUTION COMPLETE"
    print_status "Modules executed: $audit_count"
    print_status "Total execution time: ${duration}s"
    
    # Display summary
    if [ "$success" = true ]; then
        display_summary
        exit 0
    else
        print_error "Some audit modules failed. Check logs for details."
        exit 1
    fi
}

# Handle script interruption
trap 'print_error "Audit interrupted by user"; exit 130' INT

# Run main function with all arguments
main "$@"