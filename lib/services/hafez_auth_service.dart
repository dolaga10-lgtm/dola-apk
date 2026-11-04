import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool isOffline;
  final String? expireDate;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.isOffline = false,
    this.expireDate,
  });

  factory AuthResult.success({bool isOffline = false, String? expireDate}) {
    return AuthResult(
      isSuccess: true,
      isOffline: isOffline,
      expireDate: expireDate,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class HafezAuthService {
  static const String apiUrl =
      'https://dola-license-server.dolaga10.workers.dev/login';
  static const String licenseKey = 'dolaga1122wwqq';

  static const String keyUser = 'hz_u';
  static const String keyPass = 'hz_p';
  static const String keySession = 'hz_sess';

  /// محاولة تسجيل الدخول عبر السيرفر الرسمي
  static Future<AuthResult> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      return AuthResult.error('يرجى إدخال اسم المستخدم وكلمة المرور!');
    }

    final prefs = await SharedPreferences.getInstance();

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse(apiUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-License-Key', licenseKey);

      final payload = jsonEncode({
        'username': cleanUser,
        'password': cleanPass,
        'hwid': '',
      });

      request.add(utf8.encode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {}

      if (data['ok'] == true) {
        final expire = data['expire']?.toString() ?? '';
        final sessionData = jsonEncode({'u': cleanUser, 'expire': expire});
        await prefs.setString(keySession, sessionData);

        if (rememberMe) {
          await prefs.setString(keyUser, cleanUser);
          await prefs.setString(keyPass, cleanPass);
        } else {
          await prefs.remove(keyUser);
          await prefs.remove(keyPass);
        }

        return AuthResult.success(expireDate: expire);
      } else {
        final reason = data['reason']?.toString() ?? '';
        String msg = 'اسم المستخدم أو كلمة المرور غير صحيحة!';
        if (reason == 'expired') {
          msg = 'عفواً، انتهت فترة صلاحية هذا الاشتراك!';
        } else if (reason == 'device_mismatch') {
          msg = '🚫 هذا الحساب مقترن بجهاز آخر ولا يمكن الدخول من الموبايل.';
        }
        return AuthResult.error(msg);
      }
    } catch (e) {
      // فحص الجلسة المخزنة في حالة عدم وجود إنترنت
      final cachedRaw = prefs.getString(keySession);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final cached = jsonDecode(cachedRaw) as Map<String, dynamic>;
          final cachedUser = cached['u']?.toString() ?? '';
          final expireStr = cached['expire']?.toString() ?? '';

          if (cachedUser == cleanUser && expireStr.isNotEmpty) {
            final expireDate = DateTime.tryParse(expireStr);
            if (expireDate != null && expireDate.isAfter(DateTime.now())) {
              return AuthResult.success(isOffline: true, expireDate: expireStr);
            }
          }
        } catch (_) {}
      }

      return AuthResult.error(
          'خطأ في الاتصال بالسيرفر! يرجى التحقق من اتصال الإنترنت.');
    }
  }

  /// جلب البيانات المحفوظة إن وجدت
  static Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'u': prefs.getString(keyUser) ?? '',
      'p': prefs.getString(keyPass) ?? '',
    };
  }

  /// تسجيل الخروج وحذف الجلسة
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUser);
    await prefs.remove(keyPass);
    await prefs.remove(keySession);
  }

  /// التحقق من اسم المستخدم النشط
  static Future<String> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(keySession);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final cached = jsonDecode(cachedRaw) as Map<String, dynamic>;
        return cached['u']?.toString() ?? 'شركة الحافظ';
      } catch (_) {}
    }
    return prefs.getString(keyUser) ?? 'شركة الحافظ';
  }
}
