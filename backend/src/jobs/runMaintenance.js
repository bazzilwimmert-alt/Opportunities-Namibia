// Standalone maintenance job: expire lapsed memberships and pull new vacancies.
// Run via cron: `npm run maintenance:run`.
const { expireMemberships, sendExpiryReminders } = require('../services/membership');
const { ingestAll } = require('../services/ingest');
const prisma = require('../db');

(async () => {
  const expired = await expireMemberships();
  console.log(`[maintenance] expired ${expired} membership(s)`);
  const reminded = await sendExpiryReminders();
  console.log(`[maintenance] sent ${reminded} expiry reminder(s)`);
  const ingest = await ingestAll();
  console.log(`[maintenance] ingested ${ingest.created} new job(s) from ${ingest.sources} source(s)`);
  await prisma.$disconnect();
})();
