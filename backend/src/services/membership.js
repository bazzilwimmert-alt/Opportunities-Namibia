const prisma = require('../db');
const config = require('../config');
const { notifyUser, fmtDate } = require('./notify');

function addMonths(date, months) {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
}

// A user has access to vacancies only while their membership is ACTIVE and the
// paid period has not elapsed. Otherwise access is revoked.
function hasAccess(membership) {
  if (!membership) return false;
  if (membership.status !== 'ACTIVE') return false;
  if (!membership.currentPeriodEnd) return false;
  return new Date(membership.currentPeriodEnd).getTime() > Date.now();
}

async function ensureMembership(userId) {
  let m = await prisma.membership.findUnique({ where: { userId } });
  if (!m) {
    m = await prisma.membership.create({
      data: {
        userId,
        status: 'INACTIVE',
        priceCents: config.membership.priceCents,
        currency: config.membership.currency,
        periodMonths: config.membership.periodMonths,
      },
    });
  }
  return m;
}

// Grant (or extend) access for one membership period. If the member still has
// time left, the new period is appended to the existing end date.
async function activateForPeriod(userId, months) {
  const m = await ensureMembership(userId);
  const period = months || config.membership.periodMonths;
  const base = hasAccess(m) ? m.currentPeriodEnd : new Date();
  const newEnd = addMonths(base, period);
  return prisma.membership.update({
    where: { userId },
    // Clear the reminder flag so the "expiring soon" notice fires again for
    // the new period.
    data: { status: 'ACTIVE', currentPeriodEnd: newEnd, expiryReminderSentAt: null },
  });
}

async function markPending(userId) {
  const m = await ensureMembership(userId);
  // Don't downgrade an already-active member who is paying ahead.
  if (hasAccess(m)) return m;
  return prisma.membership.update({
    where: { userId },
    data: { status: 'PENDING' },
  });
}

// Mark memberships whose paid period has lapsed as EXPIRED so access is revoked
// until a new payment is confirmed. Each affected member is notified.
async function expireMemberships() {
  const due = await prisma.membership.findMany({
    where: { status: 'ACTIVE', currentPeriodEnd: { lt: new Date() } },
    include: { user: true },
  });
  for (const m of due) {
    await prisma.membership.update({ where: { id: m.id }, data: { status: 'EXPIRED' } });
    await notifyUser(m.user, {
      type: 'EXPIRED',
      title: 'Your membership has expired',
      body:
        `Hi ${m.user.fullName || ''}, your 6-month access to Opportunities Namibia ` +
        `has expired. Pay N$${(m.priceCents / 100).toFixed(0)} to ` +
        `${config.payment.phone} and submit your payment in the app to restore access.`,
    });
  }
  return due.length;
}

// Notify members whose access lapses within the reminder window, once per
// period. Returns how many reminders were sent.
async function sendExpiryReminders() {
  const now = new Date();
  const cutoff = new Date(now.getTime());
  cutoff.setDate(cutoff.getDate() + config.notifications.reminderDaysBefore);
  const soon = await prisma.membership.findMany({
    where: {
      status: 'ACTIVE',
      currentPeriodEnd: { gt: now, lte: cutoff },
      expiryReminderSentAt: null,
    },
    include: { user: true },
  });
  for (const m of soon) {
    await notifyUser(m.user, {
      type: 'EXPIRING_SOON',
      title: 'Your membership is expiring soon',
      body:
        `Hi ${m.user.fullName || ''}, your access to Opportunities Namibia ends on ` +
        `${fmtDate(m.currentPeriodEnd)}. Pay N$${(m.priceCents / 100).toFixed(0)} to ` +
        `${config.payment.phone} and submit your payment in the app to stay subscribed.`,
    });
    await prisma.membership.update({
      where: { id: m.id },
      data: { expiryReminderSentAt: now },
    });
  }
  return soon.length;
}

module.exports = {
  addMonths,
  hasAccess,
  ensureMembership,
  activateForPeriod,
  markPending,
  expireMemberships,
  sendExpiryReminders,
};
