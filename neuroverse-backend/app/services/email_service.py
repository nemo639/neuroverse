"""
Email Service - OTP, notifications, and transactional emails
"""

from typing import Optional
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.core.config import settings


class EmailService:
    """Email service for sending OTP and notifications."""
    
    def __init__(self):
        self.smtp_server = settings.MAIL_SERVER
        self.smtp_port = settings.MAIL_PORT
        self.username = settings.MAIL_USERNAME
        self.password = settings.MAIL_PASSWORD
        self.from_email = settings.MAIL_FROM
        self.from_name = settings.MAIL_FROM_NAME
    
    async def send_otp_email(self, to_email: str, otp: str, name: str) -> bool:
        """Send OTP verification email."""
        subject = "NeuroVerse - Verify Your Email"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .otp-box {{ background: #667eea; color: white; font-size: 32px; letter-spacing: 8px; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #888; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🧠 NeuroVerse</h1>
                    <p>AI-Powered Neurological Health Screening</p>
                </div>
                <div class="content">
                    <h2>Hello {name}!</h2>
                    <p>Welcome to NeuroVerse. Please use the following OTP to verify your email address:</p>
                    <div class="otp-box">{otp}</div>
                    <p><strong>This code will expire in {settings.OTP_EXPIRE_MINUTES} minutes.</strong></p>
                    <p>If you didn't request this verification, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>© 2024 NeuroVerse. All rights reserved.</p>
                    <p>This is an automated message, please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return await self._send_email(to_email, subject, html_content)
    
    async def send_password_reset_email(self, to_email: str, otp: str, name: str) -> bool:
        """Send password reset OTP email."""
        subject = "NeuroVerse - Password Reset"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .otp-box {{ background: #f5576c; color: white; font-size: 32px; letter-spacing: 8px; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; }}
                .warning {{ background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin: 15px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #888; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Password Reset</h1>
                    <p>NeuroVerse Account Recovery</p>
                </div>
                <div class="content">
                    <h2>Hello {name},</h2>
                    <p>We received a request to reset your password. Use this OTP to proceed:</p>
                    <div class="otp-box">{otp}</div>
                    <p><strong>This code will expire in {settings.OTP_EXPIRE_MINUTES} minutes.</strong></p>
                    <div class="warning">
                        ⚠️ If you didn't request a password reset, please ignore this email and your password will remain unchanged.
                    </div>
                </div>
                <div class="footer">
                    <p>© 2024 NeuroVerse. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return await self._send_email(to_email, subject, html_content)
    
    async def send_report_ready_email(self, to_email: str, name: str, report_title: str) -> bool:
        """Send notification when report is ready."""
        subject = "NeuroVerse - Your Report is Ready"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .report-box {{ background: white; border: 2px solid #11998e; padding: 20px; border-radius: 8px; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #888; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📊 Report Ready</h1>
                    <p>Your NeuroVerse Assessment Report</p>
                </div>
                <div class="content">
                    <h2>Hello {name}!</h2>
                    <p>Great news! Your neurological assessment report is now ready.</p>
                    <div class="report-box">
                        <h3>📄 {report_title}</h3>
                        <p>View and download your report from the NeuroVerse app.</p>
                    </div>
                    <p>Open the NeuroVerse app and navigate to Reports to view your results.</p>
                </div>
                <div class="footer">
                    <p>© 2024 NeuroVerse. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return await self._send_email(to_email, subject, html_content)
    
    async def send_risk_alert_email(
        self, 
        to_email: str, 
        name: str, 
        risk_type: str, 
        risk_score: float
    ) -> bool:
        """Send alert for elevated risk scores."""
        subject = f"NeuroVerse - Important Health Update"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .alert-box {{ background: #fff5f5; border: 2px solid #ff416c; padding: 20px; border-radius: 8px; margin: 20px 0; }}
                .recommendation {{ background: #e8f5e9; padding: 15px; border-radius: 8px; margin: 15px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #888; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>⚠️ Health Alert</h1>
                    <p>Important Information About Your Assessment</p>
                </div>
                <div class="content">
                    <h2>Hello {name},</h2>
                    <p>Your recent NeuroVerse assessment has identified some patterns that warrant attention.</p>
                    <div class="alert-box">
                        <h3>{risk_type} Risk Assessment</h3>
                        <p>Risk Score: <strong>{risk_score:.1f}%</strong></p>
                    </div>
                    <div class="recommendation">
                        <h4>📋 Recommended Actions:</h4>
                        <ul>
                            <li>Review your detailed results in the NeuroVerse app</li>
                            <li>Share these results with your healthcare provider</li>
                            <li>Schedule a follow-up assessment in 2-4 weeks</li>
                        </ul>
                    </div>
                    <p><em>Note: NeuroVerse is a screening tool and not a diagnostic device. Please consult with healthcare professionals for medical advice.</em></p>
                </div>
                <div class="footer">
                    <p>© 2024 NeuroVerse. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return await self._send_email(to_email, subject, html_content)
    
    async def _send_email(self, to_email: str, subject: str, html_content: str) -> bool:
        """Send email via SMTP."""
        if not self.username or not self.password:
            print(f"Email not configured. Would send to {to_email}: {subject}")
            return True  # Return True in dev mode
        
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = f"{self.from_name} <{self.from_email}>"
            msg['To'] = to_email
            
            # Attach HTML content
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Send email
            if settings.MAIL_STARTTLS:
                server = smtplib.SMTP(self.smtp_server, self.smtp_port)
                server.starttls()
            else:
                server = smtplib.SMTP_SSL(self.smtp_server, self.smtp_port)
            
            server.login(self.username, self.password)
            server.sendmail(self.from_email, to_email, msg.as_string())
            server.quit()
            
            return True
            
        except Exception as e:
            print(f"Failed to send email: {e}")
            return False
