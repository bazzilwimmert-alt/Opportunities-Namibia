const nodemailer = require('nodemailer');
const prisma = require('../db');
const config = require('../config');

// ---------------------------------------------------------------------------
// Notifications.
//
// Every notification is stored in-app (the Notification table) so members see
// it inside the app regardless of email setup. If SMTP is configured it is also
// emailed; otherwise it is logged to the server console. This keeps the feature
// fully functional with zero external credentials and lets you flip on real
// email later by setting SMTP_* env vars.
// ---------------------------------------------------------------------------

let transporter = null;
function getTransporter() {
  const { smtp } = config.notifications;
  if (!smtp.host) return null;
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: smtp.host,
      port: smtp.port,
      secure: smtp.secure,
      auth: smtp.user ? { user: smtp.user, pass: smtp.pass } : undefined,
    });
  }
  return transporter;
}

async function sendEmail(to, subject, text) {
  const t = getTransporter();
  if (!t) {
    console.log(`[notify] (email disabled) to=${to} subject="${subject}"`);
    return false;
  }
  try {
    await t.sendMail({ from: config.notifications.fromEmail, to, subject, text });
    return true;
  } catch (err) {
    console.error('[notify] email failed:', err.message);
    return false;
  }
}

// Create an in-app notification for a user and (optionally) email it.
async function notifyUser(user, { type, title, body }) {
  await prisma.notification.create({
    data: { userId: user.id, type, title, body },
  });
  if (user.email) await sendEmail(user.email, title, body);
  console.log(`[notify] ${type} -> ${user.email || user.id}: ${title}`);
}

function fmtDate(d) {
  return new Date(d).toLocaleDateString('en-GB', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
}

async function notifyPaymentConfirmed(user, periodEnd) {
  return notifyUser(user, {
    type: 'PAYMENT_CONFIRMED',
    title: 'Payment confirmed — you now have access',
    body:
      `Hi ${user.fullName || ''}, your payment has been confirmed. You now have ` +
      `full access to all vacancies on Opportunities Namibia until ${fmtDate(periodEnd)}.`,
  });
}

async function notifyPaymentRejected(user) {
  return notifyUser(user, {
    type: 'PAYMENT_REJECTED',
    title: 'Payment could not be confirmed',
    body:
      `Hi ${user.fullName || ''}, we could not confirm your recent payment. ` +
      `Please check the amount and reference and submit your payment again, or ` +
      'contact support if you believe this is a mistake.',
  });
}

module.exports = {
  notifyUser,
  notifyPaymentConfirmed,
  notifyPaymentRejected,
  fmtDate,
};
