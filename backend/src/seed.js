const prisma = require('./db');
const config = require('./config');
const { hashPassword } = require('./utils/auth');

// Legal, public sample video streams used as placeholders. MP4 progressive
// streams are used so playback works reliably across web (Chrome), Android,
// Windows and iOS for the demo. The streamUrl field also accepts HLS/DASH
// manifest URLs for real licensed live feeds (played natively on mobile) -
// replace these via the admin panel once you have your CRAN-licensed feeds.
const SAMPLE_STREAMS = [
  'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
];

function stream(i) {
  return SAMPLE_STREAMS[i % SAMPLE_STREAMS.length];
}

const SPORTS = [
  { name: 'Soccer', slug: 'soccer', icon: '⚽', channels: ['Bax Soccer 1', 'Bax Soccer 2', 'Premier Highlights'] },
  { name: 'Basketball', slug: 'basketball', icon: '🏀', channels: ['Bax Hoops', 'Court Live'] },
  { name: 'Formula One', slug: 'formula-one', icon: '🏎️', channels: ['Bax F1 Live', 'Pit Lane'] },
  { name: 'Tennis', slug: 'tennis', icon: '🎾', channels: ['Bax Tennis', 'Grand Slam'] },
  { name: 'Swimming', slug: 'swimming', icon: '🏊', channels: ['Bax Aquatics'] },
  { name: 'Cricket', slug: 'cricket', icon: '🏏', channels: ['Bax Cricket', 'Test Match Live'] },
  { name: 'Rugby', slug: 'rugby', icon: '🏉', channels: ['Bax Rugby', 'Scrum Live'] },
  { name: 'American Football', slug: 'american-football', icon: '🏈', channels: ['Bax Gridiron'] },
  { name: 'Boxing', slug: 'boxing', icon: '🥊', channels: ['Bax Fight Night'] },
];

async function main() {
  console.log('Seeding Bax database...');

  // Admin user
  const adminEmail = config.admin.email.toLowerCase();
  const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existingAdmin) {
    const admin = await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: await hashPassword(config.admin.password),
        fullName: 'Bax Admin',
        role: 'ADMIN',
        ageConfirmed: true,
        termsAcceptedAt: new Date(),
      },
    });
    await prisma.subscription.create({
      data: {
        userId: admin.id,
        status: 'ACTIVE',
        priceCents: config.subscription.priceCents,
        currency: config.subscription.currency,
        currentPeriodEnd: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      },
    });
    await prisma.profile.create({ data: { userId: admin.id, name: 'Admin' } });
    console.log(`  Admin created: ${adminEmail} / ${config.admin.password}`);
  } else {
    console.log('  Admin already exists, skipping');
  }

  // Sports + channels
  let streamIdx = 0;
  for (let s = 0; s < SPORTS.length; s += 1) {
    const def = SPORTS[s];
    const sport = await prisma.sport.upsert({
      where: { slug: def.slug },
      create: { name: def.name, slug: def.slug, icon: def.icon, sortOrder: s },
      update: { name: def.name, icon: def.icon, sortOrder: s },
    });
    const existingChannels = await prisma.channel.count({ where: { sportId: sport.id } });
    if (existingChannels === 0) {
      for (let c = 0; c < def.channels.length; c += 1) {
        await prisma.channel.create({
          data: {
            sportId: sport.id,
            name: def.channels[c],
            description: `Live ${def.name.toLowerCase()} coverage on Bax`,
            streamUrl: stream(streamIdx++),
            isLive: true,
            sortOrder: c,
          },
        });
      }
    }
  }
  console.log(`  Seeded ${SPORTS.length} sports with channels`);

  // Default platform settings
  const defaults = {
    appName: 'Bax',
    tagline: 'All sports. One subscription.',
    supportEmail: 'support@bax.tv',
  };
  for (const [key, value] of Object.entries(defaults)) {
    await prisma.setting.upsert({ where: { key }, create: { key, value }, update: {} });
  }

  console.log('Done.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
