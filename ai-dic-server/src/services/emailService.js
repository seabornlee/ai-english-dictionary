const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const APP_URL = process.env.APP_URL || 'http://localhost:3000';

const EMAIL_STYLES = `
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f3f0ff; margin: 0; padding: 20px; }
    .container { max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%); padding: 32px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 24px; font-weight: 700; }
    .header p { color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px; }
    .content { padding: 32px; }
    .content h2 { color: #18181b; margin: 0 0 16px; font-size: 20px; }
    .content p { color: #52525b; line-height: 1.6; margin: 0 0 16px; font-size: 14px; }
    .button { display: inline-block; background: #8b5cf6; color: #ffffff !important; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-weight: 600; font-size: 14px; margin: 16px 0; }
    .button:hover { background: #7c3aed; }
    .footer { padding: 24px 32px; background: #fafafa; text-align: center; }
    .footer p { color: #a1a1aa; font-size: 12px; margin: 0; }
    .features { display: flex; gap: 16px; margin: 24px 0; }
    .feature { flex: 1; text-align: center; padding: 16px; background: #f9f9fb; border-radius: 12px; }
    .feature-icon { font-size: 24px; margin-bottom: 8px; }
    .feature-text { color: #52525b; font-size: 12px; }
  </style>
`;

function baseTemplate(content) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      ${EMAIL_STYLES}
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Lexis Dic</h1>
          <p>AI-Powered English Dictionary</p>
        </div>
        ${content}
        <div class="footer">
          <p>If you didn't create an account, please ignore this email.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

async function sendVerificationEmail(email, token) {
  const verifyUrl = `${APP_URL}/api/auth/verify-email/${token}`;

  const content = `
    <div class="content">
      <h2>Welcome to Lexis Dic!</h2>
      <p>Thank you for signing up. Please verify your email address to activate your account and start exploring words with AI-powered definitions.</p>
      <div style="text-align: center;">
        <a href="${verifyUrl}" class="button">Verify Email Address</a>
      </div>
      <p style="color: #a1a1aa; font-size: 12px; margin-top: 24px;">This link expires in 24 hours.</p>
    </div>
  `;

  try {
    await resend.emails.send({
      from: 'Lexis Dic <noreply@resend.dev>',
      to: email,
      subject: 'Welcome to Lexis Dic - Verify Your Email',
      html: baseTemplate(content),
    });
    return true;
  } catch (error) {
    console.error('Failed to send verification email:', error);
    return false;
  }
}

module.exports = { sendVerificationEmail };
