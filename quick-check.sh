#!/bin/bash

# Ultimate SEO Audit System - Quick Check Script
# Fast SEO health check focusing on critical issues

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Display banner
display_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ___        _      _      _____ _               _    
   / _ \ _   _(_) ___| | __ / ____| |__   ___  ___| | __
  | | | | | | | |/ __| |/ /| |   | '_ \ / _ \/ __| |/ /
  | |_| | |_| | | (__|   < | |___| | | |  __/ (__|   < 
   \__\_\\__,_|_|\___|_|\_\ \____|_| |_|\___|\___|_|\_\
                                                      
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}SEO Quick Health Check${NC}"
    echo -e "${CYAN}Fast assessment of critical SEO factors${NC}"
    echo ""
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 <website_url>

Performs a quick SEO health check focusing on:
- Basic technical SEO factors
- Performance overview
- Meta tags validation
- Mobile optimization
- Security check

EXAMPLES:
    $0 https://example.com
    $0 example.com

EOF
}

# Quick technical checks using curl and basic tools
quick_technical_check() {
    local url="$1"
    local domain=$(echo "$url" | sed -E 's#https?://##' | sed 's#/.*##')
    
    echo -e "\n${BLUE}🔧 TECHNICAL SEO CHECK${NC}"
    echo "========================="
    
    # Check HTTPS
    if [[ "$url" == https://* ]]; then
        print_status "HTTPS enabled"
    else
        print_warning "HTTPS not detected - consider enabling SSL"
    fi
    
    # Check robots.txt
    echo -n "Checking robots.txt... "
    if curl -s -o /dev/null -w "%{http_code}" "${url%/}/robots.txt" | grep -q "200"; then
        print_status "robots.txt found"
    else
        print_warning "robots.txt not found or inaccessible"
    fi
    
    # Check sitemap
    echo -n "Checking XML sitemap... "
    sitemap_found=false
    for sitemap_url in "${url%/}/sitemap.xml" "${url%/}/sitemap_index.xml"; do
        if curl -s -o /dev/null -w "%{http_code}" "$sitemap_url" | grep -q "200"; then
            print_status "XML sitemap found"
            sitemap_found=true
            break
        fi
    done
    
    if [ "$sitemap_found" = false ]; then
        print_warning "XML sitemap not found"
    fi
    
    # Check response time
    echo -n "Checking response time... "
    response_time=$(curl -w "@-" -o /dev/null -s "$url" <<< '%{time_total}')
    response_time_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "0")
    
    if (( $(echo "$response_time < 2" | bc -l) )); then
        print_status "Fast response time (${response_time}s)"
    elif (( $(echo "$response_time < 4" | bc -l) )); then
        print_warning "Moderate response time (${response_time}s)"
    else
        print_error "Slow response time (${response_time}s) - optimize server performance"
    fi
    
    # Check status code
    echo -n "Checking HTTP status... "
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$status_code" = "200" ]; then
        print_status "HTTP 200 OK"
    else
        print_error "HTTP $status_code - check for errors"
    fi
}

# Quick page content analysis
quick_content_check() {
    local url="$1"
    
    echo -e "\n${BLUE}📝 CONTENT & META TAGS CHECK${NC}"
    echo "================================"
    
    # Fetch page content
    local content=$(curl -s -L "$url" | head -c 50000)  # First 50KB
    
    if [ -z "$content" ]; then
        print_error "Could not fetch page content"
        return 1
    fi
    
    # Check title tag
    echo -n "Checking title tag... "
    if echo "$content" | grep -qi "<title>"; then
        title=$(echo "$content" | grep -i "<title>" | sed -e 's/<[^>]*>//g' | head -1 | tr -d '\n\r')
        title_length=${#title}
        
        if [ $title_length -ge 30 ] && [ $title_length -le 60 ]; then
            print_status "Title tag length optimal (${title_length} chars)"
        elif [ $title_length -lt 30 ]; then
            print_warning "Title tag too short (${title_length} chars) - aim for 30-60"
        elif [ $title_length -gt 60 ]; then
            print_warning "Title tag too long (${title_length} chars) - may be truncated"
        fi
        
        print_info "Title: $(echo "$title" | head -c 80)..."
    else
        print_error "No title tag found"
    fi
    
    # Check meta description
    echo -n "Checking meta description... "
    if echo "$content" | grep -qi 'name="description"'; then
        meta_desc=$(echo "$content" | grep -i 'name="description"' | sed -e 's/.*content="//i' -e 's/".*//' | head -1)
        desc_length=${#meta_desc}
        
        if [ $desc_length -ge 150 ] && [ $desc_length -le 160 ]; then
            print_status "Meta description length optimal (${desc_length} chars)"
        elif [ $desc_length -lt 150 ]; then
            print_warning "Meta description too short (${desc_length} chars)"
        elif [ $desc_length -gt 160 ]; then
            print_warning "Meta description too long (${desc_length} chars)"
        fi
        
        print_info "Description: $(echo "$meta_desc" | head -c 80)..."
    else
        print_error "No meta description found"
    fi
    
    # Check H1 tags
    echo -n "Checking H1 tags... "
    h1_count=$(echo "$content" | grep -ci "<h1")
    if [ $h1_count -eq 1 ]; then
        print_status "One H1 tag found (optimal)"
    elif [ $h1_count -eq 0 ]; then
        print_error "No H1 tag found"
    else
        print_warning "Multiple H1 tags found ($h1_count) - use only one per page"
    fi
    
    # Check canonical tag
    echo -n "Checking canonical tag... "
    if echo "$content" | grep -qi 'rel="canonical"'; then
        print_status "Canonical tag found"
    else
        print_warning "No canonical tag found"
    fi
    
    # Check Open Graph tags
    echo -n "Checking Open Graph tags... "
    og_count=$(echo "$content" | grep -ci 'property="og:')
    if [ $og_count -ge 3 ]; then
        print_status "Open Graph tags found ($og_count)"
    elif [ $og_count -gt 0 ]; then
        print_warning "Basic Open Graph tags found ($og_count) - consider adding more"
    else
        print_warning "No Open Graph tags found"
    fi
    
    # Check viewport meta tag
    echo -n "Checking viewport meta tag... "
    if echo "$content" | grep -qi 'name="viewport"'; then
        print_status "Viewport meta tag found (mobile-friendly)"
    else
        print_error "No viewport meta tag found - not mobile-friendly"
    fi
}

# Quick performance check using curl
quick_performance_check() {
    local url="$1"
    
    echo -e "\n${BLUE}⚡ PERFORMANCE CHECK${NC}"
    echo "======================"
    
    # Check redirect chain
    echo -n "Checking redirects... "
    redirect_count=$(curl -s -L -o /dev/null -w "%{num_redirects}" "$url")
    if [ $redirect_count -eq 0 ]; then
        print_status "No redirects (optimal)"
    elif [ $redirect_count -eq 1 ]; then
        print_info "One redirect found"
    else
        print_warning "Multiple redirects found ($redirect_count) - consider reducing"
    fi
    
    # Check compression
    echo -n "Checking compression... "
    if curl -H "Accept-Encoding: gzip" -s -L "$url" -o /dev/null -w "%{size_download}" | grep -q "[0-9]"; then
        compressed_size=$(curl -H "Accept-Encoding: gzip" -s -L "$url" -o /dev/null -w "%{size_download}")
        uncompressed_size=$(curl -s -L "$url" -o /dev/null -w "%{size_download}")
        
        if [ $compressed_size -lt $uncompressed_size ]; then
            print_status "Compression enabled (saves $((uncompressed_size - compressed_size)) bytes)"
        else
            print_warning "Compression not detected"
        fi
    fi
    
    # Check for common performance headers
    echo -n "Checking cache headers... "
    headers=$(curl -I -s -L "$url")
    
    if echo "$headers" | grep -qi "cache-control"; then
        print_status "Cache-Control header found"
    else
        print_warning "No Cache-Control header found"
    fi
    
    # Check content type
    echo -n "Checking content type... "
    content_type=$(curl -I -s -L "$url" | grep -i "content-type" | head -1)
    if echo "$content_type" | grep -qi "text/html"; then
        print_status "HTML content type correct"
    else
        print_warning "Unexpected content type: $content_type"
    fi
}

# Security quick check
quick_security_check() {
    local url="$1"
    
    echo -e "\n${BLUE}🔒 SECURITY CHECK${NC}"
    echo "=================="
    
    # Check headers
    local headers=$(curl -I -s -L "$url")
    
    echo -n "Checking HSTS header... "
    if echo "$headers" | grep -qi "strict-transport-security"; then
        print_status "HSTS header found"
    else
        print_warning "No HSTS header found"
    fi
    
    echo -n "Checking X-Frame-Options... "
    if echo "$headers" | grep -qi "x-frame-options"; then
        print_status "X-Frame-Options header found"
    else
        print_warning "No X-Frame-Options header found"
    fi
    
    echo -n "Checking Content-Security-Policy... "
    if echo "$headers" | grep -qi "content-security-policy"; then
        print_status "CSP header found"
    else
        print_warning "No Content Security Policy found"
    fi
}

# Generate quick summary
generate_quick_summary() {
    local url="$1"
    
    echo -e "\n${PURPLE}📊 QUICK SUMMARY${NC}"
    echo "=================="
    
    local issues=0
    local warnings=0
    
    # Count issues from the output (rough estimation)
    # In a real implementation, you'd track these during checks
    
    echo -e "\n${GREEN}✅ RECOMMENDATIONS:${NC}"
    echo "• Run full audit for detailed analysis: ./run-audit.sh $url"
    echo "• Focus on critical issues first (❌ marks)"
    echo "• Address warnings for optimization (⚠️ marks)"
    echo "• Monitor regularly for performance tracking"
    
    echo -e "\n${CYAN}🚀 NEXT STEPS:${NC}"
    echo "• Technical audit: ./run-audit.sh --technical $url"
    echo "• Performance audit: ./run-audit.sh --performance $url"
    echo "• Content audit: ./run-audit.sh --content $url"
    echo "• Comprehensive audit: ./run-audit.sh $url"
}

# Main function
main() {
    local url="$1"
    
    display_banner
    
    # Check arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Validate and normalize URL
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
        print_info "Added https:// prefix: $url"
    fi
    
    print_info "Quick SEO check for: $url"
    print_info "Started at: $(date)"
    
    # Check if required tools are available
    local missing_tools=()
    for tool in curl bc; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools to continue"
        exit 1
    fi
    
    # Run quick checks
    local start_time=$(date +%s)
    
    quick_technical_check "$url"
    quick_content_check "$url"
    quick_performance_check "$url"
    quick_security_check "$url"
    generate_quick_summary "$url"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "\n${GREEN}Quick check completed in ${duration}s${NC}"
    echo -e "${CYAN}For detailed analysis, run: ./run-audit.sh $url${NC}"
}

# Handle script interruption
trap 'print_error "Quick check interrupted"; exit 130' INT

# Run main function
main "$@"