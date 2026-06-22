const prisma = require('./db');
const config = require('./config');
const { hashPassword } = require('./utils/auth');

// Sample Namibian vacancies (skilled + unskilled) to populate the board for
// the demo. In production these come from admin entry + automatic ingestion.
const JOBS = [
  {
    title: 'Software Developer',
    company: 'Bank Windhoek',
    location: 'Windhoek',
    category: 'IT',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$35,000 - N$45,000',
    description:
      'Build and maintain internal banking applications. Requirements: BSc in Computer Science or equivalent, 3+ years with JavaScript/Java, SQL.',
    applyEmail: 'careers@bankwindhoek.com.na',
  },
  {
    title: 'Registered Nurse',
    company: 'Lady Pohamba Private Hospital',
    location: 'Windhoek',
    category: 'Healthcare',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$28,000 - N$36,000',
    description:
      'Provide patient care in a private hospital ward. Must be registered with the Health Professions Councils of Namibia.',
    applyEmail: 'hr@ladypohamba.com.na',
  },
  {
    title: 'Diesel Mechanic',
    company: 'Namib Mills',
    location: 'Okahandja',
    category: 'Trades',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$18,000 - N$24,000',
    description:
      'Service and repair heavy vehicles and plant machinery. Trade certificate and 2+ years experience required.',
    contact: '+264 62 501 234',
  },
  {
    title: 'General Worker',
    company: 'Ohlthaver & List Group',
    location: 'Walvis Bay',
    category: 'General',
    type: 'CONTRACT',
    skillLevel: 'UNSKILLED',
    salary: 'N$5,500 / month',
    description:
      'Assist with loading, packing and general warehouse duties. No formal qualification required; on-the-job training provided.',
    contact: '+264 64 200 000',
  },
  {
    title: 'Cleaner',
    company: 'Hilton Windhoek',
    location: 'Windhoek',
    category: 'Hospitality',
    type: 'PART_TIME',
    skillLevel: 'UNSKILLED',
    salary: 'N$4,800 / month',
    description:
      'Maintain cleanliness of hotel rooms and public areas. Reliable and hardworking individuals encouraged to apply.',
    applyEmail: 'jobs@hiltonwindhoek.com',
  },
  {
    title: 'Security Guard',
    company: 'G4S Namibia',
    location: 'Oshakati',
    category: 'Security',
    type: 'FULL_TIME',
    skillLevel: 'UNSKILLED',
    salary: 'N$5,000 / month',
    description:
      'Guard premises and control access. Grade 10 minimum; security training is an advantage.',
    contact: '+264 65 220 000',
  },
  {
    title: 'Civil Engineer',
    company: 'Roads Authority',
    location: 'Windhoek',
    category: 'Engineering',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$40,000 - N$55,000',
    description:
      'Plan and supervise road infrastructure projects. BEng Civil Engineering and ECN registration required.',
    applyUrl: 'https://www.ra.org.na/careers',
  },
  {
    title: 'Primary School Teacher',
    company: 'Ministry of Education',
    location: 'Rundu',
    category: 'Education',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$20,000 - N$28,000',
    description:
      'Teach lower primary learners. Bachelor of Education required; fluency in local languages an advantage.',
    applyEmail: 'recruitment@moe.gov.na',
  },
  {
    title: 'Farm Labourer',
    company: 'AgriNamibia Farms',
    location: 'Otjiwarongo',
    category: 'Agriculture',
    type: 'TEMPORARY',
    skillLevel: 'UNSKILLED',
    salary: 'N$160 / day',
    description:
      'Seasonal crop and livestock work. Accommodation provided. No experience required.',
    contact: '+264 67 300 111',
  },
  {
    title: 'Accountant',
    company: 'PwC Namibia',
    location: 'Windhoek',
    category: 'Finance',
    type: 'FULL_TIME',
    skillLevel: 'SKILLED',
    salary: 'N$30,000 - N$42,000',
    description:
      'Prepare financial statements and manage audits. BAcc and progress toward CA(NAM) required.',
    applyUrl: 'https://www.pwc.com/na/en/careers.html',
  },
  {
    title: 'Marketing Intern',
    company: 'MTC Namibia',
    location: 'Windhoek',
    category: 'Marketing',
    type: 'INTERNSHIP',
    skillLevel: 'SKILLED',
    salary: 'N$6,000 / month stipend',
    description:
      'Support social media and brand campaigns. Recent marketing/communications graduates welcome.',
    applyEmail: 'internships@mtc.com.na',
  },
  {
    title: 'Waiter / Waitress',
    company: 'The Stellenbosch Wine Bar',
    location: 'Swakopmund',
    category: 'Hospitality',
    type: 'PART_TIME',
    skillLevel: 'UNSKILLED',
    salary: 'N$4,500 + tips',
    description:
      'Serve food and drinks, take orders, and ensure a great guest experience. Friendly attitude essential.',
    contact: '+264 64 461 000',
  },
];

async function main() {
  console.log('Seeding Opportunities Namibia database...');

  // Admin user
  const adminEmail = config.admin.email.toLowerCase();
  const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existingAdmin) {
    const admin = await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: await hashPassword(config.admin.password),
        fullName: 'Opportunities Admin',
        role: 'ADMIN',
        termsAcceptedAt: new Date(),
      },
    });
    await prisma.membership.create({
      data: {
        userId: admin.id,
        status: 'ACTIVE',
        priceCents: config.membership.priceCents,
        currency: config.membership.currency,
        periodMonths: config.membership.periodMonths,
        currentPeriodEnd: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      },
    });
    await prisma.profile.create({ data: { userId: admin.id, name: 'Admin' } });
    console.log(`  Admin created: ${adminEmail} / ${config.admin.password}`);
  } else {
    console.log('  Admin already exists, skipping');
  }

  // Sample vacancies
  const jobCount = await prisma.job.count();
  if (jobCount === 0) {
    for (const j of JOBS) {
      await prisma.job.create({ data: { ...j, source: 'MANUAL' } });
    }
    console.log(`  Seeded ${JOBS.length} sample vacancies`);
  } else {
    console.log('  Jobs already exist, skipping');
  }

  // Sample auto-ingestion source (a public job feed). Disabled by default so
  // the demo is deterministic; the admin can enable it and click "Fetch now".
  const sourceCount = await prisma.jobSource.count();
  if (sourceCount === 0) {
    await prisma.jobSource.create({
      data: {
        name: 'Sample Jobs RSS Feed',
        type: 'RSS',
        url: 'https://weworkremotely.com/categories/remote-programming-jobs.rss',
        category: 'IT',
        enabled: false,
      },
    });
    console.log('  Seeded 1 sample job source (disabled)');
  }

  // Default platform settings (editable online by the admin)
  const defaults = {
    appName: 'Opportunities Namibia',
    tagline: 'Every Namibian job. One membership.',
    supportEmail: 'support@opportunities.na',
    paymentPhone: config.payment.phone,
    paymentAccountName: config.payment.accountName,
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
