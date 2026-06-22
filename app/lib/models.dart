class AppInfo {
  final String appName;
  final String tagline;
  final int priceCents;
  final String currency;
  final String priceDisplay;
  final int maxProfiles;
  final String supportEmail;

  AppInfo({
    required this.appName,
    required this.tagline,
    required this.priceCents,
    required this.currency,
    required this.priceDisplay,
    required this.maxProfiles,
    required this.supportEmail,
  });

  factory AppInfo.fromJson(Map<String, dynamic> j) {
    final price = j['price'] as Map<String, dynamic>? ?? {};
    return AppInfo(
      appName: j['appName'] ?? 'Bax',
      tagline: j['tagline'] ?? '',
      priceCents: price['cents'] ?? 20000,
      currency: price['currency'] ?? 'NAD',
      priceDisplay: price['display'] ?? 'N\$200/month',
      maxProfiles: j['maxProfiles'] ?? 2,
      supportEmail: j['supportEmail'] ?? 'support@bax.tv',
    );
  }
}

class Subscription {
  final String status;
  final int priceCents;
  final String currency;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  Subscription({
    required this.status,
    required this.priceCents,
    required this.currency,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        status: j['status'] ?? 'INACTIVE',
        priceCents: j['priceCents'] ?? 20000,
        currency: j['currency'] ?? 'NAD',
        currentPeriodEnd: j['currentPeriodEnd'] != null
            ? DateTime.tryParse(j['currentPeriodEnd'])
            : null,
        cancelAtPeriodEnd: j['cancelAtPeriodEnd'] ?? false,
      );
}

class Profile {
  final String id;
  final String name;
  final String? avatar;
  final bool isKids;

  Profile({required this.id, required this.name, this.avatar, this.isKids = false});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'],
        name: j['name'],
        avatar: j['avatar'],
        isKids: j['isKids'] ?? false,
      );
}

class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool entitled;
  final int? age;
  final bool isMinor;
  final bool parentalControlsEnabled;
  final int maxContentRating;
  final bool parentalPinSet;
  final int allowedRating;
  final Subscription? subscription;
  final List<Profile> profiles;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.entitled,
    required this.age,
    required this.isMinor,
    required this.parentalControlsEnabled,
    required this.maxContentRating,
    required this.parentalPinSet,
    required this.allowedRating,
    required this.subscription,
    required this.profiles,
  });

  bool get isAdmin => role == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        fullName: j['fullName'] ?? '',
        role: j['role'] ?? 'USER',
        entitled: j['entitled'] ?? false,
        age: j['age'],
        isMinor: j['isMinor'] ?? false,
        parentalControlsEnabled: j['parentalControlsEnabled'] ?? false,
        maxContentRating: j['maxContentRating'] ?? 18,
        parentalPinSet: j['parentalPinSet'] ?? false,
        allowedRating: j['allowedRating'] ?? 18,
        subscription: j['subscription'] != null
            ? Subscription.fromJson(j['subscription'])
            : null,
        profiles: ((j['profiles'] ?? []) as List)
            .map((e) => Profile.fromJson(e))
            .toList(),
      );
}

class Channel {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? poster;
  final bool isLive;
  final String? streamUrl;
  final bool locked;
  final int minAge;
  final bool parentalBlocked;

  Channel({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.poster,
    this.isLive = true,
    this.streamUrl,
    this.locked = true,
    this.minAge = 0,
    this.parentalBlocked = false,
  });

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        logo: j['logo'],
        poster: j['poster'],
        isLive: j['isLive'] ?? true,
        streamUrl: j['streamUrl'],
        locked: j['locked'] ?? true,
        minAge: j['minAge'] ?? 0,
        parentalBlocked: j['parentalBlocked'] ?? false,
      );
}

class Sport {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final List<Channel> channels;

  Sport({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.channels,
  });

  factory Sport.fromJson(Map<String, dynamic> j) => Sport(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        icon: j['icon'],
        channels: ((j['channels'] ?? []) as List)
            .map((e) => Channel.fromJson(e))
            .toList(),
      );
}
