const { hasAccess } = require('../services/membership');

function serializeUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    role: user.role,
    status: user.status,
    createdAt: user.createdAt,
    membership: serializeMembership(user.membership),
    hasAccess: hasAccess(user.membership),
    profiles: (user.profiles || []).map(serializeProfile),
  };
}

function serializeMembership(m) {
  if (!m) return null;
  return {
    status: m.status,
    priceCents: m.priceCents,
    currency: m.currency,
    periodMonths: m.periodMonths,
    currentPeriodEnd: m.currentPeriodEnd,
  };
}

function serializeProfile(p) {
  return { id: p.id, name: p.name, avatar: p.avatar, headline: p.headline };
}

function serializeJob(job, { full }) {
  const base = {
    id: job.id,
    title: job.title,
    company: job.company,
    location: job.location,
    category: job.category,
    type: job.type,
    skillLevel: job.skillLevel,
    salary: job.salary,
    source: job.source,
    postedAt: job.postedAt,
  };
  if (!full) {
    // Locked preview: withhold description and apply details until member pays.
    return { ...base, locked: true };
  }
  return {
    ...base,
    locked: false,
    description: job.description,
    applyUrl: job.applyUrl,
    applyEmail: job.applyEmail,
    contact: job.contact,
    expiresAt: job.expiresAt,
  };
}

module.exports = { serializeUser, serializeMembership, serializeProfile, serializeJob };
