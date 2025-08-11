# Ultimate SEO Audit System - Usage Guide

Complete guide for using the terminal-based SEO audit system.

## Quick Start

1. **Setup Environment**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Run Your First Audit**
   ```bash
   ./run-audit.sh https://your-website.com
   ```

3. **View Results**
   - HTML Report: `reports/seo_audit_report_[timestamp].html`
   - Executive Summary: `reports/executive_summary_[timestamp].txt`

## Available Commands

### Main Audit Scripts

```bash
# Complete comprehensive audit
./run-audit.sh https://example.com

# Quick audit (technical + performance only)
./run-audit.sh --quick https://example.com

# Individual audit modules
./run-audit.sh --technical https://example.com
./run-audit.sh --performance https://example.com
./run-audit.sh --content https://example.com
./run-audit.sh --competitive https://example.com --competitors "comp1.com,comp2.com"
```

### Quick Health Check

```bash
# Fast SEO health assessment
./quick-check.sh https://example.com
```

### Competitive Analysis

```bash
# Detailed competitive analysis
./competitive-audit.sh https://example.com https://competitor1.com,https://competitor2.com
```

### Report Generation

```bash
# Generate reports from existing audit data
python3 scripts/generate-report.py --latest

# Generate specific reports
python3 scripts/generate-report.py technical_audit.json performance_audit.json
```

### Monitoring Dashboard

```bash
# Create and start monitoring dashboard
./generate-dashboard.sh
python3 dashboard.py
# Visit: http://127.0.0.1:8050
```

## Automation Setup

### Scheduled Audits (Cron)

```bash
# Interactive cron setup
./automation/cron-setup.sh

# Manual cron examples
# Daily at 2 AM
0 2 * * * /path/to/seo-audit-system/run-audit.sh --quick https://example.com

# Weekly comprehensive audit
0 3 * * 0 /path/to/seo-audit-system/run-audit.sh https://example.com
```

### GitHub Actions CI/CD

1. Copy `.github/workflows/` folder to your repository
2. Set repository secrets:
   - `GOOGLE_PAGESPEED_API_KEY` (optional)
   - `SLACK_WEBHOOK` (optional)
3. Configure website URL in workflow file
4. Push changes to trigger automated audits

## Configuration

### Keywords Configuration

Edit `config/keywords.txt`:
```
# Primary keywords
seo audit
website optimization

# Secondary keywords
technical seo
page speed
```

### Audit Settings

Edit `config/audit-settings.json`:
```json
{
  "seo": {
    "title_length": {"min": 30, "max": 60},
    "meta_description_length": {"min": 150, "max": 160}
  },
  "performance": {
    "core_web_vitals": {
      "lcp_threshold": 2.5,
      "inp_threshold": 200,
      "cls_threshold": 0.1
    }
  }
}
```

### API Integration

Edit `config/api-config.json`:
```json
{
  "google_pagespeed": {
    "api_key": "YOUR_API_KEY"
  }
}
```

## Understanding Results

### Overall SEO Score

- **90-100**: Excellent - Your site has outstanding SEO
- **80-89**: Very Good - Minor optimizations needed  
- **70-79**: Good - Some improvements recommended
- **60-69**: Fair - Several issues need attention
- **<60**: Poor - Significant improvements required

### Core Web Vitals

- **LCP (Largest Contentful Paint)**: 
  - Good: ≤ 2.5s
  - Needs Improvement: 2.5-4.0s
  - Poor: > 4.0s

- **INP (Interaction to Next Paint)**:
  - Good: ≤ 200ms
  - Needs Improvement: 200-500ms  
  - Poor: > 500ms

- **CLS (Cumulative Layout Shift)**:
  - Good: ≤ 0.1
  - Needs Improvement: 0.1-0.25
  - Poor: > 0.25

### Issue Priorities

1. **Critical Issues** (🔴): Fix immediately
   - Missing meta tags
   - No HTTPS
   - Poor Core Web Vitals
   - Missing H1 tags

2. **High Priority** (🟡): Fix within 1-2 weeks
   - Slow page speed
   - Missing schema markup
   - Poor mobile optimization

3. **Medium Priority** (🟠): Fix within 1 month
   - Missing alt texts
   - Suboptimal content length
   - Internal linking issues

4. **Low Priority** (🟢): Optimize when possible
   - Minor readability issues
   - Additional schema markup
   - Advanced technical optimizations

## Advanced Usage

### Custom Audit Scripts

Create custom audit by modifying existing scripts:

```python
# Custom technical audit
from scripts.technical_audit import TechnicalSEOAuditor

auditor = TechnicalSEOAuditor("https://example.com")
# Add custom checks here
results = auditor.run_full_audit()
```

### Batch Processing

Audit multiple sites:
```bash
# Create site list
echo "https://site1.com" > sites.txt
echo "https://site2.com" >> sites.txt

# Batch audit
while read site; do
    ./run-audit.sh --quick "$site"
done < sites.txt
```

### Integration with External Tools

```bash
# Export data to CSV
python3 -c "
import json, pandas as pd
with open('reports/technical_audit_latest.json') as f:
    data = json.load(f)
df = pd.json_normalize(data)
df.to_csv('seo_data.csv', index=False)
"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x *.sh scripts/*.sh
   ```

2. **Python Module Not Found**
   ```bash
   # Activate virtual environment
   source venv/bin/activate
   # Or install globally
   pip3 install -r requirements.txt
   ```

3. **Lighthouse Not Found**
   ```bash
   npm install -g lighthouse
   ```

4. **Chrome/Chromium Issues**
   ```bash
   # Ubuntu/Debian
   sudo apt install chromium-browser
   # macOS
   brew install chromium
   ```

5. **Memory Issues with Large Sites**
   - Add `--max-old-space-size=4096` to Node.js commands
   - Process sites in smaller batches

### Performance Optimization

1. **Speed up audits**:
   - Use `--quick` flag for faster results
   - Limit concurrent requests in config
   - Use local Chrome installation

2. **Reduce resource usage**:
   - Process one audit at a time
   - Clear old report files regularly
   - Use headless browser mode

### Log Analysis

Check logs for detailed information:
```bash
# View recent logs
tail -f logs/audit_*.log

# Search for errors
grep -i error logs/*.log

# Monitor system resources
top -p $(pgrep -f "audit|lighthouse")
```

## Best Practices

### Regular Monitoring

1. **Schedule audits appropriately**:
   - Daily quick checks for active development
   - Weekly comprehensive audits for stable sites
   - Monthly competitive analysis

2. **Set performance budgets**:
   - Define acceptable score thresholds
   - Alert on significant degradations
   - Track improvements over time

3. **Automate responses**:
   - Set up Slack/email notifications
   - Create tickets for critical issues
   - Generate executive reports for stakeholders

### Data Management

1. **Archive old reports**:
   ```bash
   # Archive reports older than 30 days
   find reports/ -name "*.json" -mtime +30 -exec mv {} data/archive/ \;
   ```

2. **Backup configurations**:
   ```bash
   tar -czf seo-audit-backup.tar.gz config/ automation/
   ```

### Team Collaboration

1. **Share configurations**:
   - Commit config files to version control
   - Document custom settings
   - Maintain keyword lists collaboratively

2. **Standardize reporting**:
   - Use consistent audit schedules
   - Define team-specific thresholds
   - Create standard operating procedures

## Support and Resources

### Getting Help

1. **Documentation**: Check README.md and script comments
2. **Logs**: Review detailed logs in `logs/` directory  
3. **Issues**: Common problems and solutions in this guide

### External Resources

- [Google PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/)
- [Core Web Vitals](https://web.dev/vitals/)
- [Lighthouse Documentation](https://developers.google.com/web/tools/lighthouse/)
- [SEO Best Practices](https://developers.google.com/search/docs/fundamentals)

### Contributing

To extend or improve the audit system:

1. **Add new audit modules**: Follow existing script patterns
2. **Enhance reporting**: Modify `generate-report.py`  
3. **Improve automation**: Update automation scripts
4. **Share configurations**: Document custom settings

---

For more detailed information, check individual script documentation and configuration files.