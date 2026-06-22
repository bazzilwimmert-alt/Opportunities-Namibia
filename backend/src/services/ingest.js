const prisma = require('../db');

// ---------------------------------------------------------------------------
// Vacancy ingestion.
//
// Sources are pluggable via an adapter per `type`. A working RSS adapter ships
// here (most job boards expose RSS/Atom feeds). LinkedIn is intentionally NOT
// scraped: their Terms of Service prohibit scraping and they actively block it.
// To ingest LinkedIn jobs lawfully you must use their official Jobs API /
// partner access and supply a token, which the adapter below documents.
// ---------------------------------------------------------------------------

function decodeEntities(s) {
  if (!s) return '';
  return s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tag(block, name) {
  const m = block.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)<\\/${name}>`, 'i'));
  return m ? decodeEntities(m[1]) : '';
}

// Parse an RSS 2.0 or Atom feed into normalized job items.
function parseFeed(xml) {
  const items = [];
  const blocks = xml.match(/<item[\s\S]*?<\/item>/gi) ||
    xml.match(/<entry[\s\S]*?<\/entry>/gi) || [];
  for (const b of blocks) {
    let link = tag(b, 'link');
    if (!link) {
      const hrefMatch = b.match(/<link[^>]*href="([^"]+)"/i);
      if (hrefMatch) link = hrefMatch[1];
    }
    const title = tag(b, 'title');
    if (!title) continue;
    items.push({
      title,
      link,
      guid: tag(b, 'guid') || link || title,
      description: tag(b, 'description') || tag(b, 'summary') || tag(b, 'content'),
      pubDate: tag(b, 'pubDate') || tag(b, 'updated') || tag(b, 'published'),
      company: tag(b, 'company') || tag(b, 'author') || tag(b, 'dc:creator'),
      raw: b,
    });
  }
  return items;
}

function guessSkillLevel(text) {
  const t = (text || '').toLowerCase();
  const unskilled = ['general worker', 'cleaner', 'labourer', 'laborer', 'cashier',
    'driver', 'security guard', 'waiter', 'waitress', 'packer', 'farm', 'domestic',
    'gardener', 'porter', 'shop assistant'];
  return unskilled.some((w) => t.includes(w)) ? 'UNSKILLED' : 'SKILLED';
}

// Pull a human location out of a feed item; fall back to the source default.
function guessLocation(item, fallback) {
  const loc = tag(item.raw || '', 'location') ||
    tag(item.raw || '', 'job:location') ||
    tag(item.raw || '', 'region');
  if (loc) return loc.slice(0, 120);
  const m = (item.title || '').match(/\(([^)]+)\)\s*$/); // "Title (Windhoek)"
  if (m) return m[1].slice(0, 120);
  return fallback || 'Namibia';
}

function matchesKeywords(item, keywords) {
  if (!keywords) return true;
  const terms = keywords.split(',').map((k) => k.trim().toLowerCase()).filter(Boolean);
  if (!terms.length) return true;
  const hay = `${item.title} ${item.description} ${item.company}`.toLowerCase();
  return terms.some((k) => hay.includes(k));
}

async function ingestRss(source) {
  const res = await fetch(source.url, {
    headers: { 'User-Agent': 'OpportunitiesNamibia/1.0 (+jobs ingestion)' },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const xml = await res.text();
  const items = parseFeed(xml);

  let created = 0;
  let kept = 0;
  for (const it of items) {
    if (!matchesKeywords(it, source.keywords)) continue;
    kept += 1;
    const externalId = `${source.id}:${it.guid}`;
    const existing = await prisma.job.findUnique({ where: { externalId } });
    if (existing) continue;
    await prisma.job.create({
      data: {
        title: it.title.slice(0, 200),
        company: (it.company || source.name).slice(0, 120),
        location: guessLocation(it, source.location),
        category: source.category || 'General',
        skillLevel: guessSkillLevel(`${it.title} ${it.description}`),
        description: it.description || it.title,
        applyUrl: it.link || null,
        source: 'RSS',
        externalId,
        postedAt: it.pubDate && !Number.isNaN(Date.parse(it.pubDate))
          ? new Date(it.pubDate)
          : new Date(),
      },
    });
    created += 1;
  }
  return { found: kept, created };
}

function ingestLinkedIn() {
  // Scraping LinkedIn breaches their Terms of Service. Enable this only with
  // official LinkedIn Jobs API / partner credentials.
  throw new Error(
    'LinkedIn ingestion is disabled. LinkedIn\'s Terms of Service prohibit ' +
    'scraping; use their official Jobs API with partner credentials instead.'
  );
}

async function ingestSource(source) {
  let result;
  try {
    if (source.type === 'LINKEDIN') {
      result = ingestLinkedIn(source);
    } else {
      result = await ingestRss(source);
    }
    await prisma.jobSource.update({
      where: { id: source.id },
      data: {
        lastFetchedAt: new Date(),
        lastResult: `OK: ${result.created} new of ${result.found}`,
      },
    });
    return { ...result, ok: true };
  } catch (err) {
    await prisma.jobSource.update({
      where: { id: source.id },
      data: { lastFetchedAt: new Date(), lastResult: `ERROR: ${err.message}` },
    });
    return { ok: false, error: err.message };
  }
}

async function ingestAll() {
  const sources = await prisma.jobSource.findMany({ where: { enabled: true } });
  let created = 0;
  for (const s of sources) {
    const r = await ingestSource(s);
    if (r.ok) created += r.created;
  }
  return { sources: sources.length, created };
}

module.exports = { ingestSource, ingestAll, parseFeed };
