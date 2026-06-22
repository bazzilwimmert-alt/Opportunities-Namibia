class AppInfo {
  final String appName;
  final String tagline;
  final int priceCents;
  final String currency;
  final String priceDisplay;
  final int periodMonths;
  final int maxProfiles;
  final String supportEmail;
  final String paymentPhone;
  final String paymentAccountName;

  AppInfo({
    required this.appName,
    required this.tagline,
    required this.priceCents,
    required this.currency,
    required this.priceDisplay,
    required this.periodMonths,
    required this.maxProfiles,
    required this.supportEmail,
    required this.paymentPhone,
    required this.paymentAccountName,
  });

  factory AppInfo.fromJson(Map<String, dynamic> j) {
    final price = j['price'] as Map<String, dynamic>? ?? {};
    final payment = j['payment'] as Map<String, dynamic>? ?? {};
    return AppInfo(
      appName: j['appName'] ?? 'Opportunities Namibia',
      tagline: j['tagline'] ?? '',
      priceCents: price['cents'] ?? 20000,
      currency: price['currency'] ?? 'NAD',
      priceDisplay: price['display'] ?? 'N\$200 / 6 months',
      periodMonths: price['periodMonths'] ?? 6,
      maxProfiles: j['maxProfiles'] ?? 2,
      supportEmail: j['supportEmail'] ?? 'support@opportunities.na',
      paymentPhone: payment['phone'] ?? '+264814680324',
      paymentAccountName: payment['accountName'] ?? 'Opportunities Namibia',
    );
  }
}

class Membership {
  final String status;
  final int priceCents;
  final String currency;
  final int periodMonths;
  final DateTime? currentPeriodEnd;

  Membership({
    required this.status,
    required this.priceCents,
    required this.currency,
    required this.periodMonths,
    required this.currentPeriodEnd,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING';

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        status: j['status'] ?? 'INACTIVE',
        priceCents: j['priceCents'] ?? 20000,
        currency: j['currency'] ?? 'NAD',
        periodMonths: j['periodMonths'] ?? 6,
        currentPeriodEnd: j['currentPeriodEnd'] != null
            ? DateTime.tryParse(j['currentPeriodEnd'])
            : null,
      );
}

class Profile {
  final String id;
  final String name;
  final String? avatar;
  final String? headline;

  Profile({required this.id, required this.name, this.avatar, this.headline});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'],
        name: j['name'],
        avatar: j['avatar'],
        headline: j['headline'],
      );
}

class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool hasAccess;
  final Membership? membership;
  final List<Profile> profiles;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.hasAccess,
    required this.membership,
    required this.profiles,
  });

  bool get isAdmin => role == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        fullName: j['fullName'] ?? '',
        phone: j['phone'],
        role: j['role'] ?? 'USER',
        hasAccess: j['hasAccess'] ?? false,
        membership: j['membership'] != null
            ? Membership.fromJson(j['membership'])
            : null,
        profiles: ((j['profiles'] ?? []) as List)
            .map((e) => Profile.fromJson(e))
            .toList(),
      );
}

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String category;
  final String type;
  final String skillLevel;
  final String? salary;
  final String source;
  final DateTime? postedAt;
  final bool locked;
  final String? description;
  final String? applyUrl;
  final String? applyEmail;
  final String? contact;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.category,
    required this.type,
    required this.skillLevel,
    this.salary,
    required this.source,
    this.postedAt,
    required this.locked,
    this.description,
    this.applyUrl,
    this.applyEmail,
    this.contact,
  });

  bool get isUnskilled => skillLevel == 'UNSKILLED';

  String get typeLabel {
    switch (type) {
      case 'PART_TIME':
        return 'Part-time';
      case 'CONTRACT':
        return 'Contract';
      case 'TEMPORARY':
        return 'Temporary';
      case 'INTERNSHIP':
        return 'Internship';
      default:
        return 'Full-time';
    }
  }

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'],
        title: j['title'] ?? '',
        company: j['company'] ?? '',
        location: j['location'] ?? 'Namibia',
        category: j['category'] ?? 'General',
        type: j['type'] ?? 'FULL_TIME',
        skillLevel: j['skillLevel'] ?? 'SKILLED',
        salary: j['salary'],
        source: j['source'] ?? 'MANUAL',
        postedAt:
            j['postedAt'] != null ? DateTime.tryParse(j['postedAt']) : null,
        locked: j['locked'] ?? true,
        description: j['description'],
        applyUrl: j['applyUrl'],
        applyEmail: j['applyEmail'],
        contact: j['contact'],
      );
}
