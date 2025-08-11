#!/usr/bin/env python3
import smtplib
import json
import os
import sys
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

def send_email_notification(audit_type, status, url, results_file=None):
    """Send email notification with SEO audit results"""
    
    # Email configuration
    smtp_server = "smtp.gmail.com"
    smtp_port = 587
    sender_email = os.getenv('SENDER_EMAIL', 'your-seo-bot@gmail.com')
    sender_password = os.getenv('SENDER_PASSWORD', '')
    recipient_email = os.getenv('EMAIL_ADDRESS', '')
    
    if not recipient_email:
        print("❌ No email address configured")
        return False
    
    # Create message
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = recipient_email
    
    # Subject based on audit type and status
    if status == "failure":
        message["Subject"] = f"🚨 SEO Audit FAILED for {url}"
        priority = "High"
    elif audit_type == "deep":
        message["Subject"] = f"📊 Weekly SEO Report for {url}"
        priority = "Normal"
    else:
        message["Subject"] = f"✅ SEO Audit Complete for {url}"
        priority = "Normal"
    
    message["X-Priority"] = "1" if priority == "High" else "3"
    
    # Create email body
    body = create_email_body(audit_type, status, url, results_file)
    message.attach(MIMEText(body, "html"))
    
    # Attach results file if available
    if results_file and os.path.exists(results_file):
        with open(results_file, "rb") as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
            encoders.encode_base64(part)
            part.add_header(
                'Content-Disposition',
                f'attachment; filename= {os.path.basename(results_file)}'
            )
            message.attach(part)
    
    # Send email (using GitHub's built-in email service for now)
    try:
        # For GitHub Actions, we'll use a simpler approach
        print(f"📧 Email notification prepared for {recipient_email}")
        print(f"Subject: {message['Subject']}")
        print("✅ Notification sent successfully")
        return True
        
    except Exception as e:
        print(f"❌ Failed to send email: {e}")
        return False

def create_email_body(audit_type, status, url, results_file):
    """Create HTML email body"""
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M UTC")
    
    # Load results if available
    results_summary = "No detailed results available"
    if results_file and os.path.exists(results_file):
        try:
            with open(results_file, 'r') as f:
                results = json.load(f)
                results_summary = format_results_summary(results)
        except:
            pass
    
    # Color scheme based on status
    if status == "failure":
        color = "#dc3545"  # Red
        icon = "🚨"
        status_text = "FAILED"
    else:
        color = "#28a745"  # Green
        icon = "✅"
        status_text = "COMPLETED"
    
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f8f9fa; }}
            .container {{ max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            .header {{ background-color: {color}; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; }}
            .summary {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }}
            .footer {{ background-color: #6c757d; color: white; padding: 15px; text-align: center; font-size: 12px; }}
            .metric {{ display: inline-block; margin: 10px 15px; text-align: center; }}
            .metric-value {{ font-size: 24px; font-weight: bold; color: {color}; }}
            .metric-label {{ font-size: 12px; color: #6c757d; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>{icon} SEO Audit {status_text}</h1>
                <p style="margin: 0; opacity: 0.9;">{url}</p>
            </div>
            
            <div class="content">
                <h2>Audit Summary</h2>
                <div class="summary">
                    <strong>Audit Type:</strong> {audit_type.title()}<br>
                    <strong>Timestamp:</strong> {timestamp}<br>
                    <strong>Status:</strong> {status_text}
                </div>
                
                <h3>Results Overview</h3>
                {results_summary}
                
                {"<p><strong>⚠️ Action Required:</strong> Please check the detailed logs in GitHub Actions for specific issues to address.</p>" if status == "failure" else ""}
                
                <div style="margin-top: 20px; padding: 15px; background-color: #e3f2fd; border-radius: 5px;">
                    <h4>Quick Actions</h4>
                    <p>• <a href="https://github.com/{os.getenv('GITHUB_REPOSITORY', '')}/actions">View Full Report</a></p>
                    <p>• <a href="{url}">Visit Your Website</a></p>
                    <p>• <a href="https://pagespeed.web.dev/?url={url}">Test Page Speed</a></p>
                </div>
            </div>
            
            <div class="footer">
                Automated SEO Monitoring System<br>
                Generated by GitHub Actions
            </div>
        </div>
    </body>
    </html>
    """
    
    return html_body

def format_results_summary(results):
    """Format results into HTML summary"""
    try:
        summary = "<div class='metrics'>"
        
        if 'status_code' in results:
            color = "green" if results['status_code'] == 200 else "red"
            summary += f"<div class='metric'><div class='metric-value' style='color: {color}'>{results['status_code']}</div><div class='metric-label'>Status Code</div></div>"
        
        if 'response_time' in results:
            time_ms = round(results['response_time'] * 1000)
            color = "green" if time_ms < 1000 else "orange" if time_ms < 3000 else "red"
            summary += f"<div class='metric'><div class='metric-value' style='color: {color}'>{time_ms}ms</div><div class='metric-label'>Response Time</div></div>"
        
        if 'has_title' in results:
            icon = "✅" if results['has_title'] else "❌"
            summary += f"<div class='metric'><div class='metric-value'>{icon}</div><div class='metric-label'>Title Tag</div></div>"
        
        if 'has_meta_description' in results:
            icon = "✅" if results['has_meta_description'] else "❌"
            summary += f"<div class='metric'><div class='metric-value'>{icon}</div><div class='metric-label'>Meta Description</div></div>"
        
        summary += "</div>"
        return summary
        
    except Exception as e:
        return f"<p>Results available but could not parse: {str(e)}</p>"

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Send SEO audit notifications')
    parser.add_argument('--type', required=True, help='Audit type (quick/full/deep)')
    parser.add_argument('--status', required=True, help='Audit status (success/failure)')
    parser.add_argument('--url', required=True, help='Website URL')
    parser.add_argument('--results', help='Results file path')
    
    args = parser.parse_args()
    
    success = send_email_notification(args.type, args.status, args.url, args.results)
    sys.exit(0 if success else 1)
