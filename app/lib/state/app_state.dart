import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../models.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  AppInfo? appInfo;
  User? user;
  Profile? activeProfile;
  List<Job> jobs = [];
  List<String> categories = [];
  List<NotificationItem> notifications = [];
  int unreadCount = 0;
  bool booting = true;

  bool get isLoggedIn => user != null;
  bool get hasAccess => user?.hasAccess ?? false;

  Future<void> bootstrap() async {
    booting = true;
    notifyListeners();
    try {
      final cfg = await api.get('/api/public/config');
      appInfo = AppInfo.fromJson(cfg);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('opp_token');
    if (token != null) {
      api.setToken(token);
      try {
        final me = await api.get('/api/auth/me');
        user = User.fromJson(me['user']);
        activeProfile = user!.profiles.isNotEmpty ? user!.profiles.first : null;
      } catch (_) {
        await _clearToken();
      }
    }
    booting = false;
    notifyListeners();
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('opp_token', token);
    api.setToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('opp_token');
    api.setToken(null);
  }

  Future<void> login(String email, String password) async {
    final res = await api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    await _persistToken(res['token']);
    user = User.fromJson(res['user']);
    activeProfile = user!.profiles.isNotEmpty ? user!.profiles.first : null;
    notifyListeners();
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required bool acceptTerms,
  }) async {
    final res = await api.post('/api/auth/signup', {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'acceptTerms': acceptTerms,
    });
    await _persistToken(res['token']);
    user = User.fromJson(res['user']);
    activeProfile = user!.profiles.isNotEmpty ? user!.profiles.first : null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearToken();
    user = null;
    activeProfile = null;
    jobs = [];
    notifications = [];
    unreadCount = 0;
    notifyListeners();
  }

  // ---- Notifications ----
  Future<void> loadNotifications() async {
    final res = await api.get('/api/notifications');
    notifications = (res['notifications'] as List)
        .map((e) => NotificationItem.fromJson(e))
        .toList();
    unreadCount = res['unread'] ?? 0;
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await api.post('/api/notifications/read-all', {});
    await loadNotifications();
  }

  Future<void> refreshUser() async {
    final me = await api.get('/api/auth/me');
    user = User.fromJson(me['user']);
    notifyListeners();
  }

  void setActiveProfile(Profile p) {
    activeProfile = p;
    notifyListeners();
  }

  // ---- Vacancies ----
  Future<void> loadJobs({
    String? q,
    String? category,
    String? skillLevel,
    String? type,
  }) async {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (skillLevel != null && skillLevel.isNotEmpty) params['skillLevel'] = skillLevel;
    if (type != null && type.isNotEmpty) params['type'] = type;
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await api.get('/api/jobs$query');
    jobs = (res['jobs'] as List).map((e) => Job.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final res = await api.get('/api/jobs/categories');
    categories = (res['categories'] as List).map((e) => e.toString()).toList();
    notifyListeners();
  }

  // ---- Membership / manual payment ----
  Future<Map<String, dynamic>> getMembership() async {
    final res = await api.get('/api/membership');
    return Map<String, dynamic>.from(res);
  }

  Future<void> submitPayment({String? reference, String? payerPhone}) async {
    await api.post('/api/membership/pay', {
      if (reference != null) 'reference': reference,
      if (payerPhone != null) 'payerPhone': payerPhone,
    });
    await refreshUser();
  }

  // ---- Profiles ----
  Future<void> createProfile(String name, {String? headline}) async {
    await api.post('/api/profiles', {
      'name': name,
      if (headline != null && headline.isNotEmpty) 'headline': headline,
    });
    await refreshUser();
  }

  Future<void> deleteProfile(String id) async {
    await api.delete('/api/profiles/$id');
    await refreshUser();
  }
}
