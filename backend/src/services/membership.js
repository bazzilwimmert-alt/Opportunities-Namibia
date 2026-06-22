const prisma = require('../db');
const config = require('../config');

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
    data: { status: 'ACTIVE', currentPeriodEnd: newEnd },
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
// until a new payment is confirmed.
async function expireMemberships() {
  const result = await prisma.membership.updateMany({
    where: { status: 'ACTIVE', currentPeriodEnd: { lt: new Date() } },
    data: { status: 'EXPIRED' },
  });
  return result.count;
}

module.exports = {
  addMonths,
  hasAccess,
  ensureMembership,
  activateForPeriod,
  markPending,
  expireMemberships,
};
