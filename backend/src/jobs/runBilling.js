// Standalone billing job: revoke streaming rights for lapsed subscriptions.
// Run via cron: `npm run billing:run`.
const { revokeExpiredSubscriptions } = require('../services/subscription');
const prisma = require('../db');

(async () => {
  const count = await revokeExpiredSubscriptions();
  console.log(`[billing] revoked ${count} expired subscription(s)`);
  await prisma.$disconnect();
})();
