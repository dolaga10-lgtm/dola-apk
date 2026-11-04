import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة تسجيل الدخول والسبلاش الأنيميشين المطابقة لتطبيق شركة الحافظ الأصلي
class HafezAuthGateScreen extends StatefulWidget {
  final Widget onAuthenticatedChild;
  const HafezAuthGateScreen({super.key, required this.onAuthenticatedChild});

  @override
  State<HafezAuthGateScreen> createState() => _HafezAuthGateScreenState();
}

class _HafezAuthGateScreenState extends State<HafezAuthGateScreen>
    with SingleTickerProviderStateMixin {
  static const String _kApiUrl =
      'https://dola-license-server.dolaga10.workers.dev/login';
  static const String _kLicenseKey = 'dolaga1122wwqq';

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  // تأثيرات السبلاش الحركية من تطبيق الحافظ
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _splashZoomed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnim = Tween<double>(begin: 0.15, end: 1.05).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.0, 0.4)),
    );

    _animCtrl.forward().then((_) {
      if (mounted) setState(() => _splashZoomed = true);
    });

    _checkSavedSession();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('hz_u') ?? '';
    final p = prefs.getString('hz_p') ?? '';
    final sessRaw = prefs.getString('hz_sess') ?? '';

    if (u.isNotEmpty && p.isNotEmpty) {
      _userCtrl.text = u;
      _passCtrl.text = p;

      // تحقق أولاً من الجلسة المخزنة محلياً (Offline)
      if (sessRaw.isNotEmpty) {
        try {
          final sess = jsonDecode(sessRaw);
          if (sess['u'] == u) {
            final exp = DateTime.tryParse(sess['expire'] ?? '');
            if (exp == null || exp.isAfter(DateTime.now())) {
              await Future.delayed(const Duration(milliseconds: 1800));
              if (mounted) setState(() => _isAuthenticated = true);
              return;
            }
          }
        } catch (_) {}
      }

      // محاولة التحقق عبر السيرفر في الخلفية
      await Future.delayed(const Duration(milliseconds: 1800));
      _performLogin(silent: true);
    }
  }

  Future<void> _performLogin({bool silent = false}) async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();

    if (u.isEmpty || p.isEmpty) {
      if (!silent) {
        setState(() => _errorMessage = 'برجاء كتابة الاسم وكلمة المرور!');
      }
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await http
          .post(
            Uri.parse(_kApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-License-Key': _kLicenseKey,
            },
            body: jsonEncode({
              'username': u,
              'password': p,
              'hwid': '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('hz_u', u);
          await prefs.setString('hz_p', p);
        } else {
          await prefs.remove('hz_u');
          await prefs.remove('hz_p');
        }
        await prefs.setString(
          'hz_sess',
          jsonEncode({'u': u, 'expire': data['expire'] ?? ''}),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAuthenticated = true;
          });
        }
        return;
      } else {
        // التحقق من الجلسة المحلية في حال عدم توفر اتصال
        final prefs = await SharedPreferences.getInstance();
        final sessRaw = prefs.getString('hz_sess');
        if (sessRaw != null) {
          final sess = jsonDecode(sessRaw);
          if (sess['u'] == u) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isAuthenticated = true;
              });
            }
            return;
          }
        }

        if (!silent && mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = data['msg'] ??
                data['error'] ??
                'اسم المستخدم أو كلمة المرور غير صحيحة!';
          });
        }
      }
    } catch (_) {
      // Offline fallback: لو كان المستخدم مسجل مسبقاً بنفس الاسم يسمح له بالدخول
      final prefs = await SharedPreferences.getInstance();
      final sessRaw = prefs.getString('hz_sess');
      if (sessRaw != null) {
        final sess = jsonDecode(sessRaw);
        if (sess['u'] == u) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isAuthenticated = true;
            });
          }
          return;
        }
      }

      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'تعذر الاتصال بسيرفر التراخيص، تحقق من الإنترنت أو بيانات الدخول.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.onAuthenticatedChild;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B110A),
      body: Stack(
        children: [
          // خلفية السبلاش الأنيميشين مع اللوجو والصورة
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (ctx, _) {
                return Opacity(
                  opacity: _fadeAnim.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/splash.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // تدرج لوني فخم وطبعة ذهبية (Glow & Overlay)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B110A).withOpacity(0.85),
                    const Color(0xFF1B110A).withOpacity(0.65),
                    const Color(0xFF1B110A).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // واجهة تسجيل الدخول
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة وشعار شركة الحافظ
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/hafez_icon.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'شركة الحافظ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'خبرة منذ سنة 1980\nفي تصنيع المطابخ الألومنيوم والخشب والواجهات الزجاجية',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFFFDE68A), height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    // صندوق تسجيل الدخول المربوط بسيرفر الحافظ
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'تسجيل الدخول — شركة الحافظ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _userCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'اسم المستخدم',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person, color: Color(0xFFF59E0B)),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passCtrl,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.key, color: Color(0xFFF59E0B)),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFFF59E0B),
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? true),
                              ),
                              const Text('تذكرني على هذا الجهاز',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : () => _performLogin(),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'دخول ✨',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
