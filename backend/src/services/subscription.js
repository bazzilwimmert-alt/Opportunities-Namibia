const prisma = require('../db');
const config = require('../config');

const MONTH_MS = 30 * 24 * 60 * 60 * 1000;

// A user is entitled to stream only when their subscription is ACTIVE and the
// paid period has not elapsed. Otherwise streaming rights are revoked.
function isEntitled(subscription) {
  if (!subscription) return false;
  if (subscription.status !== 'ACTIVE') return false;
  if (!subscription.currentPeriodEnd) return false;
  return new Date(subscription.currentPeriodEnd).getTime() > Date.now();
}

async function ensureSubscription(userId) {
  let sub = await prisma.subscription.findUnique({ where: { userId } });
  if (!sub) {
    sub = await prisma.subscription.create({
      data: {
        userId,
        status: 'INACTIVE',
        priceCents: config.subscription.priceCents,
        currency: config.subscription.currency,
      },
    });
  }
  return sub;
}

// Called when a payment is confirmed PAID. Extends the period by one month.
async function activateForPaidPeriod(userId, periodEnd) {
  await ensureSubscription(userId);
  const newEnd = periodEnd || new Date(Date.now() + MONTH_MS);
  return prisma.subscription.update({
    where: { userId },
    data: { status: 'ACTIVE', currentPeriodEnd: newEnd, cancelAtPeriodEnd: false },
  });
}

// Marks subscriptions whose paid period has lapsed as PAST_DUE so streaming
// rights are revoked until a new payment is made.
async function revokeExpiredSubscriptions() {
  const now = new Date();
  const result = await prisma.subscription.updateMany({
    where: {
      status: 'ACTIVE',
      currentPeriodEnd: { lt: now },
    },
    data: { status: 'PAST_DUE' },
  });
  return result.count;
}

module.exports = {
  MONTH_MS,
  isEntitled,
  ensureSubscription,
  activateForPaidPeriod,
  revokeExpiredSubscriptions,
};
