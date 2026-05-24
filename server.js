const express = require('express');
const path = require('path');
const nodemailer = require('nodemailer');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public'), { extensions: ['html'] }));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/api/contact', async (req, res) => {
  const { firstName, lastName, phone, email, vehicle, message, source } = req.body;

  if (!firstName || !lastName || !phone) {
    return res.status(400).json({ success: false, error: 'Missing required fields' });
  }

  const transporter = nodemailer.createTransport({
    host: 'smtp.hostinger.com',
    port: 465,
    secure: true,
    auth: {
      user: 'greetings@brakeknights.com',
      pass: process.env.SMTP_PASS
    }
  });

  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:20px;border:1px solid #ddd;border-radius:8px;">
      <div style="background:#0a1f3d;padding:16px 20px;border-radius:6px 6px 0 0;margin:-20px -20px 20px;">
        <h2 style="color:#c9a84c;margin:0;font-size:1.3rem;">⚔️ New Service Request — Brake Knights</h2>
      </div>
      <table style="width:100%;border-collapse:collapse;font-size:0.95rem;">
        <tr><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;width:130px;">Name</td><td style="padding:8px 12px;">${firstName} ${lastName}</td></tr>
        <tr style="background:#f9f9f9;"><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;">Phone</td><td style="padding:8px 12px;"><a href="tel:${phone}">${phone}</a></td></tr>
        <tr><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;">Email</td><td style="padding:8px 12px;"><a href="mailto:${email}">${email || 'Not provided'}</a></td></tr>
        <tr style="background:#f9f9f9;"><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;">Vehicle</td><td style="padding:8px 12px;">${vehicle || 'Not provided'}</td></tr>
        <tr><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;">Message</td><td style="padding:8px 12px;">${message || 'None'}</td></tr>
        <tr style="background:#f9f9f9;"><td style="padding:8px 12px;font-weight:bold;color:#0a1f3d;">Source</td><td style="padding:8px 12px;">${source || 'Website'}</td></tr>
      </table>
      <div style="margin-top:20px;padding:12px;background:#fff8e1;border-left:4px solid #c9a84c;border-radius:4px;font-size:0.85rem;color:#555;">
        Reply directly to this email to respond to the customer.
      </div>
    </div>
  `;

  if (!process.env.SMTP_PASS) {
    console.error('SMTP_PASS environment variable is not set');
    return res.status(500).json({ success: false, error: 'Email not configured' });
  }

  try {
    await transporter.sendMail({
      from: '"Brake Knights Website" <greetings@brakeknights.com>',
      to: 'greetings@brakeknights.com',
      replyTo: email || 'greetings@brakeknights.com',
      subject: `New Service Request: ${firstName} ${lastName} — ${phone}`,
      html
    });
    res.json({ success: true });
  } catch (err) {
    console.error('Email send error:', err.code, err.message);
    res.status(500).json({ success: false, error: 'Failed to send email' });
  }
});

app.listen(PORT, () => {
  console.log(`Brakeknights server running on port ${PORT}`);
});
