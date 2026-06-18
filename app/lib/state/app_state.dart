import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../models.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  AppInfo? appInfo;
  User? user;
  Profile? activeProfile;
  List<Sport> sports = [];
  bool booting = true;

  bool get isLoggedIn => user != null;
  bool get isEntitled => user?.entitled ?? false;

  Future<void> bootstrap() async {
    booting = true;
    notifyListeners();
    try {
      final cfg = await api.get('/api/public/config');
      appInfo = AppInfo.fromJson(cfg);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('bax_token');
    if (token != null) {
      api.setToken(token);
      try {
        final me = await api.get('/api/auth/me');
        user = User.fromJson(me['user']);
      } catch (_) {
        await _clearToken();
      }
    }
    booting = false;
    notifyListeners();
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bax_token', token);
    api.setToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bax_token');
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
    required bool ageConfirmed,
    required bool acceptTerms,
  }) async {
    final res = await api.post('/api/auth/signup', {
      'email': email,
      'password': password,
      'fullName': fullName,
      'ageConfirmed': ageConfirmed,
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
    sports = [];
    notifyListeners();
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

  // ---- Catalog ----
  Future<void> loadCatalog() async {
    final res = await api.get('/api/catalog/sports');
    sports = (res['sports'] as List).map((e) => Sport.fromJson(e)).toList();
    notifyListeners();
  }

  Future<String> getPlayUrl(String channelId) async {
    final res = await api.get('/api/catalog/channels/$channelId/play');
    return res['streamUrl'] as String;
  }

  // ---- Subscription / payment ----
  Future<Map<String, dynamic>> startCheckout() async {
    final res = await api.post('/api/subscription/checkout', {});
    return Map<String, dynamic>.from(res);
  }

  Future<void> confirmSandboxPayment(String paymentId) async {
    await api.post('/api/subscription/sandbox/confirm', {'paymentId': paymentId});
    await refreshUser();
  }

  Future<void> cancelSubscription() async {
    await api.post('/api/subscription/cancel', {});
    await refreshUser();
  }

  // ---- Profiles ----
  Future<void> createProfile(String name, {bool isKids = false}) async {
    await api.post('/api/profiles', {'name': name, 'isKids': isKids});
    await refreshUser();
  }

  Future<void> deleteProfile(String id) async {
    await api.delete('/api/profiles/$id');
    await refreshUser();
  }
}
