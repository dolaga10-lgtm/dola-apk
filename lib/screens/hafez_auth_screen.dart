import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/hafez_auth_service.dart';
import '../services/workshop_storage.dart';

class HafezAuthScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const HafezAuthScreen({super.key, required this.storage});

  @override
  State<HafezAuthScreen> createState() => _HafezAuthScreenState();
}

class _HafezAuthScreenState extends State<HafezAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showLoginForm = false;
  String? _errorMessage;
  String _statusMessage = 'مرحباً بكم في شركة الحافظ';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );

    _animCtrl.forward();
    _checkInitialAutoLogin();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkInitialAutoLogin() async {
    final creds = await HafezAuthService.getSavedCredentials();
    final savedUser = creds['u'] ?? '';
    final savedPass = creds['p'] ?? '';

    if (savedUser.isNotEmpty && savedPass.isNotEmpty) {
      _userCtrl.text = savedUser;
      _passCtrl.text = savedPass;
      setState(() {
        _statusMessage = 'جاري التحقق التلقائي من الاشتراك... ⏳';
        _isLoading = true;
      });

      // إعطاء وقت كافٍ للمستخدم للاستمتاع بشاشة الافتتاحية
      await Future.delayed(const Duration(milliseconds: 1600));

      final res = await HafezAuthService.login(
        username: savedUser,
        password: savedPass,
        rememberMe: true,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        _navigateToApp();
        return;
      } else {
        setState(() {
          _isLoading = false;
          _showLoginForm = true;
          _errorMessage = res.errorMessage;
          _statusMessage = 'برجاء تسجيل الدخول للمتابعة';
        });
      }
    } else {
      // بعد ثانيتين و نصف، إظهار نموذج تسجيل الدخول
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      setState(() {
        _showLoginForm = true;
        _statusMessage = 'بوابة تسجيل دخول شركة الحافظ';
      });
    }
  }

  Future<void> _submitLogin() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();

    if (u.isEmpty || p.isEmpty) {
      setState(() {
        _errorMessage = 'برجاء كتابة اسم المستخدم وكلمة المرور!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'جاري التحقق من البيانات... ⏳';
    });

    final res = await HafezAuthService.login(
      username: u,
      password: p,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (res.isSuccess) {
      _navigateToApp();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.errorMessage;
        _statusMessage = 'فشل تسجيل الدخول';
      });
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => MainWorkshopShell(storage: widget.storage),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1B110A),
      body: Stack(
        children: [
          // 1. الخلفية الكاملة لشعار وخامة شركة الحافظ
          Positioned.fill(
            child: Image.asset(
              'assets/images/hafez_splash.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1B110A),
              ),
            ),
          ),

          // 2. تدرج لوني فخم داكن يعزز قراءة النصوص والنموذج
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.40),
                    const Color(0xFF1B110A).withOpacity(0.70),
                    const Color(0xFF1B110A).withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),

          // 3. المحتوى المتمركز (الافتتاحية أو بطاقة الدخول)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // الشعار العلوي
                            _buildTopBrandingHeader(),
                            const SizedBox(height: 24),

                            // بطاقة الدخول أو مؤشر التحقق
                            if (_showLoginForm)
                              _buildLoginCard(size)
                            else
                              _buildSplashGreeting(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الهيدر التعريفي للشركة
  Widget _buildTopBrandingHeader() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8C872), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8C872).withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/hafez_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'شركة الحافظ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE8C872),
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'خبرة منذ سنة 1981',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF3E6C4),
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'تصنيع المطابخ الألومنيوم والخشب والواجهات الزجاجية',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4C5A9),
          ),
        ),
      ],
    );
  }

  /// شاشة الترحيب أثناء شاشة الافتتاحية
  Widget _buildSplashGreeting() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8C872)),
          strokeWidth: 2.8,
        ),
        const SizedBox(height: 18),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF3E6C4),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// بطاقة تسجيل الدخول
  Widget _buildLoginCard(Size size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: size.width > 380 ? 360 : size.width * 0.92,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B110A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFC9B27A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🔐 تسجيل الدخول للنظام',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF3E6C4),
                ),
              ),
              const SizedBox(height: 18),

              // حقل اسم المستخدم
              TextFormField(
                controller: _userCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'اسم المستخدم',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFC9B27A)),
                  filled: true,
                  fillColor: const Color(0xFF2A1B10),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6B5636)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6B5636)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8C872), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // حقل كلمة المرور
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC9B27A)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFC9B27A),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A1B10),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6B5636)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6B5636)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8C872), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // تذكرني
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFFE8C872),
                    checkColor: const Color(0xFF1B110A),
                    side: const BorderSide(color: Color(0xFFC9B27A), width: 1.5),
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  ),
                  const Text(
                    'تذكرني على هذا الجهاز',
                    style: TextStyle(
                      color: Color(0xFFF3E6C4),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // رسالة الخطأ
              if (_errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade400, width: 1),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // زر الدخول
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9B866),
                    foregroundColor: const Color(0xFF1B110A),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF1B110A)),
                          ),
                        )
                      : const Text(
                          'دخول ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
