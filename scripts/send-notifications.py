#!/usr/bin/env python3
import json
import os
import sys
import requests
from datetime import datetime

class SEONotificationSystem:
    def __init__(self):
        self.email = os.getenv('EMAIL_ADDRESS', 'wellz.levi@gmail.com')
        self.slack_webhook = os.getenv('SLACK_WEBHOOK_URL', '')
        self.discord_webhook = os.getenv('DISCORD_WEBHOOK_URL', '')
        self.github_repo = os.getenv('GITHUB_REPOSITORY', '')
        self.github_run_id = os.getenv('GITHUB_RUN_ID', '')
        
    def send_notifications(self, audit_type, status, url, results_file=None):
        """Send notifications through all configured channels"""
        
        # Load results
        results = self.load_results(results_file)
        
        # Determine notification urgency
        urgency = self.determine_urgency(results, status)
        
        print(f"📧 Sending {urgency} notifications for {audit_type} audit")
        
        # Send through all available channels
        notifications_sent = []
        
        # 1. Console Summary (Always)
        self.send_console_notification(audit_type, status, url, results)
        notifications_sent.append("Console")
        
        # 2. Email Summary (Always)
        if self.send_email_notification(audit_type, status, url, results, urgency):
            notifications_sent.append("Email")
        
        # 3. Slack (If webhook configured)
        if self.slack_webhook and self.send_slack_notification(audit_type, status, url, results, urgency):
            notifications_sent.append("Slack")
        
        # 4. Discord (If webhook configured)
        if self.discord_webhook and self.send_discord_notification(audit_type, status, url, results, urgency):
            notifications_sent.append("Discord")
        
        # 5. GitHub Issue (For critical problems)
        if urgency == "CRITICAL" and self.create_github_issue(audit_type, status, url, results):
            notifications_sent.append("GitHub Issue")
        
        print(f"✅ Notifications sent via: {', '.join(notifications_sent)}")
        return len(notifications_sent) > 0
    
    def load_results(self, results_file):
        """Load audit results from file"""
        if not results_file or not os.path.exists(results_file):
            return {"error": "No results file found"}
        
        try:
            with open(results_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            return {"error": f"Could not load results: {e}"}
    
    def determine_urgency(self, results, status):
        """Determine notification urgency level"""
        if status == "failure":
            return "CRITICAL"
        
        if "error" in results:
            return "CRITICAL"
        
        score = results.get("score", 100)
        critical_issues = results.get("critical_issues", 0)
        
        if score < 50 or critical_issues > 3:
            return "HIGH"
        elif score < 70 or critical_issues > 0:
            return "MEDIUM"
        else:
            return "LOW"
    
    def send_console_notification(self, audit_type, status, url, results):
        """Send detailed console notification"""
        print("\n" + "="*60)
        print("📊 SEO AUDIT NOTIFICATION SUMMARY")
        print("="*60)
        
        print(f"🌐 Website: {url}")
        print(f"📋 Audit Type: {audit_type.upper()}")
        print(f"⏰ Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"📈 Status: {status.upper()}")
        
        if "error" not in results:
            score = results.get("score", 0)
            grade = results.get("grade", "N/A")
            print(f"🎯 SEO Score: {score}/100 ({grade})")
            
            # Performance metrics
            if "response_time_ms" in results:
                response_time = results["response_time_ms"]
                speed_emoji = "🚀" if response_time < 1000 else "⚠️" if response_time < 3000 else "🐌"
                print(f"{speed_emoji} Response Time: {response_time}ms")
            
            # Issues summary
            issues = results.get("issues", [])
            recommendations = results.get("recommendations", [])
            
            if issues:
                print(f"\n🚨 Issues Found ({len(issues)}):")
                for i, issue in enumerate(issues[:5], 1):
                    print(f"   {i}. {issue}")
                if len(issues) > 5:
                    print(f"   ... and {len(issues) - 5} more issues")
            else:
                print("\n✅ No critical issues found!")
            
            if recommendations:
                print(f"\n💡 Top Recommendations ({len(recommendations)}):")
                for i, rec in enumerate(recommendations[:3], 1):
                    print(f"   {i}. {rec}")
        else:
            print(f"❌ Error: {results['error']}")
        
        print("\n🔗 Quick Actions:")
        print(f"   • View your website: {url}")
        print(f"   • Test page speed: https://pagespeed.web.dev/?url={url}")
        if self.github_repo and self.github_run_id:
            print(f"   • View full report: https://github.com/{self.github_repo}/actions/runs/{self.github_run_id}")
        
        print("="*60)
    
    def send_email_notification(self, audit_type, status, url, results, urgency):
        """Generate email notification content"""
        print(f"\n📧 Preparing email notification for {self.email}")
        
        # Email subject
        if urgency == "CRITICAL":
            subject = f"🚨 CRITICAL: SEO Issues Detected - {url}"
        elif urgency == "HIGH":
            subject = f"⚠️ HIGH: SEO Problems Found - {url}"
        elif audit_type == "deep":
            subject = f"📊 Weekly SEO Report - {url}"
        else:
            score = results.get("score", 0)
            subject = f"✅ SEO Audit Complete - Score: {score}/100 - {url}"
        
        # Email body
        body = self.create_email_body(audit_type, status, url, results, urgency)
        
        print(f"📬 Email Subject: {subject}")
        print("📄 Email Content:")
        print("-" * 40)
        print(body[:500] + "..." if len(body) > 500 else body)
        print("-" * 40)
        print("✅ Email notification prepared")
        
        return True
    
    def create_email_body(self, audit_type, status, url, results, urgency):
        """Create detailed email body"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M UTC")
        
        # Header
        urgency_emoji = {"CRITICAL": "🚨", "HIGH": "⚠️", "MEDIUM": "📊", "LOW": "✅"}
        emoji = urgency_emoji.get(urgency, "📊")
        
        body = f"""{emoji} SEO Audit {status.upper()} - {url}

🕐 Audit Time: {timestamp}
📋 Audit Type: {audit_type.upper()}
🎯 Priority: {urgency}

"""
        
        if "error" not in results:
            score = results.get("score", 0)
            grade = results.get("grade", "N/A")
            
            body += f"""📊 PERFORMANCE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SEO Score: {score}/100 ({grade})
⚡ Response Time: {results.get('response_time_ms', 'N/A')}ms
📄 Page Size: {results.get('content_size_kb', 'N/A')} KB
🔗 Internal Links: {results.get('internal_links_count', 'N/A')}
🖼️ Images: {results.get('total_images', 'N/A')} total, {results.get('images_without_alt', 'N/A')} missing alt text

"""
            
            # Issues section
            issues = results.get("issues", [])
            if issues:
                body += f"""🚨 ISSUES FOUND ({len(issues)})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
                for i, issue in enumerate(issues, 1):
                    body += f"{i}. {issue}\n"
                body += "\n"
            
            # Recommendations section
            recommendations = results.get("recommendations", [])
            if recommendations:
                body += f"""💡 RECOMMENDATIONS ({len(recommendations)})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
                for i, rec in enumerate(recommendations, 1):
                    body += f"{i}. {rec}\n"
                body += "\n"
        else:
            body += f"❌ AUDIT ERROR: {results['error']}\n\n"
        
        # Quick actions
        body += f"""🔗 QUICK ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• View your website: {url}
• Test page speed: https://pagespeed.web.dev/?url={url}
• SEO checker: https://seochecker.it/check/{url.replace('https://', '').replace('http://', '')}
"""
        
        if self.github_repo and self.github_run_id:
            body += f"• View full report: https://github.com/{self.github_repo}/actions/runs/{self.github_run_id}\n"
        
        body += f"\n🤖 Automated SEO Monitoring System\n📅 Next audit: {self.get_next_audit_time()}"
        
        return body
    
    def send_slack_notification(self, audit_type, status, url, results, urgency):
        """Send Slack notification"""
        if not self.slack_webhook:
            return False
        
        print("📱 Sending Slack notification...")
        
        # Color coding
        color_map = {"CRITICAL": "#ff0000", "HIGH": "#ff9900", "MEDIUM": "#ffcc00", "LOW": "#00ff00"}
        color = color_map.get(urgency, "#0099ff")
        
        score = results.get("score", 0)
        grade = results.get("grade", "N/A")
        
        payload = {
            "text": f"SEO Audit {status.upper()} for {url}",
            "attachments": [{
                "color": color,
                "title": f"🎯 SEO Score: {score}/100 ({grade})",
                "title_link": url,
                "fields": [
                    {"title": "Response Time", "value": f"{results.get('response_time_ms', 'N/A')}ms", "short": True},
                    {"title": "Issues Found", "value": str(len(results.get('issues', []))), "short": True},
                    {"title": "Priority", "value": urgency, "short": True},
                    {"title": "Audit Type", "value": audit_type.upper(), "short": True}
                ],
                "footer": "SEO Monitoring Bot",
                "ts": int(datetime.now().timestamp())
            }]
        }
        
        try:
            response = requests.post(self.slack_webhook, json=payload, timeout=10)
            print("✅ Slack notification sent")
            return True
        except Exception as e:
            print(f"❌ Slack notification failed: {e}")
            return False
    
    def send_discord_notification(self, audit_type, status, url, results, urgency):
        """Send Discord notification"""
        if not self.discord_webhook:
            return False
        
        print("🎮 Sending Discord notification...")
        
        score = results.get("score", 0)
        grade = results.get("grade", "N/A")
        
        # Color coding for Discord embeds
        color_map = {"CRITICAL": 0xff0000, "HIGH": 0xff9900, "MEDIUM": 0xffcc00, "LOW": 0x00ff00}
        color = color_map.get(urgency, 0x0099ff)
        
        embed = {
            "title": f"SEO Audit {status.upper()}",
            "description": f"**Website:** {url}\n**Score:** {score}/100 ({grade})",
            "color": color,
            "fields": [
                {"name": "Response Time", "value": f"{results.get('response_time_ms', 'N/A')}ms", "inline": True},
                {"name": "Issues", "value": str(len(results.get('issues', []))), "inline": True},
                {"name": "Priority", "value": urgency, "inline": True}
            ],
            "footer": {"text": "SEO Monitoring Bot"},
            "timestamp": datetime.now().isoformat()
        }
        
        payload = {"embeds": [embed]}
        
        try:
            response = requests.post(self.discord_webhook, json=payload, timeout=10)
            print("✅ Discord notification sent")
            return True
        except Exception as e:
            print(f"❌ Discord notification failed: {e}")
            return False
    
    def create_github_issue(self, audit_type, status, url, results):
        """Create GitHub issue for critical problems"""
        print("📝 Creating GitHub issue for critical problems...")
        
        # This will be handled by the workflow's GitHub script action
        # We just prepare the data here
        
        with open('github-issue-data.json', 'w') as f:
            json.dump({
                "audit_type": audit_type,
                "status": status,
                "url": url,
                "results": results,
                "timestamp": datetime.now().isoformat()
            }, f, indent=2)
        
        print("✅ GitHub issue data prepared")
        return True
    
    def get_next_audit_time(self):
        """Calculate next audit time"""
        now = datetime.now()
        if now.hour < 8:
            return "Today at 8:00 AM UTC"
        elif now.hour < 20:
            return "Today at 8:00 PM UTC"
        else:
            return "Tomorrow at 8:00 AM UTC"

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Send SEO audit notifications')
    parser.add_argument('--type', required=True, help='Audit type (quick/full/deep)')
    parser.add_argument('--status', required=True, help='Audit status (success/failure)')
    parser.add_argument('--url', required=True, help='Website URL')
    parser.add_argument('--results', help='Results file path')
    
    args = parser.parse_args()
    
    # Initialize notification system
    notifier = SEONotificationSystem()
    
    # Send notifications
    success = notifier.send_notifications(args.type, args.status, args.url, args.results)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
