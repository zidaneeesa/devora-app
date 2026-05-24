import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'claim_lookup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  final bool showLogoutSuccess;

  const LoginScreen({super.key, this.showLogoutSuccess = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _checkingSavedLogin = true;
  bool _keepSignedIn = true;

  // Error states
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    if (widget.showLogoutSuccess) {
      _checkingSavedLogin = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Anda berhasil log out. Silakan login kembali.',
            ),
            backgroundColor: const Color(0xFF2B5A41),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkSavedLogin();
      });
    }
  }

  Future<void> _checkSavedLogin() async {
    final hasToken = await ApiService.hasSavedToken();

    if (!mounted) return;

    if (hasToken) {
      // Jalankan di background — tidak perlu ditunggu sebelum navigasi.
      NotificationService.saveFcmToken().catchError((_) {});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    setState(() => _checkingSavedLogin = false);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_emailError != null ||
        _passwordError != null ||
        _generalError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _generalError = null;
      });
    }
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    bool hasError = false;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      if (email.isEmpty) {
        _emailError = 'Email tidak boleh kosong';
        hasError = true;
      }

      if (password.isEmpty) {
        _passwordError = 'Kata sandi diperlukan';
        hasError = true;
      }
    });

    if (hasError) {
      _shake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.login(
        email,
        password,
        keepSignedIn: _keepSignedIn,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (res['status'] == 200) {
        // Registrasi FCM token ke backend setelah berhasil login
        await NotificationService.saveFcmToken();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      final data = res['data'];

      if (res['status'] == 422 && data is Map && data['errors'] != null) {
        final errors = data['errors'] as Map;

        setState(() {
          if (errors.containsKey('email')) {
            _emailError = errors['email'][0].toString();
          }

          if (errors.containsKey('password')) {
            _passwordError = errors['password'][0].toString();
          }
        });
      } else {
        setState(() {
          _generalError = data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Kredensial tidak valid.';
        });
      }

      _shake();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _generalError = 'Gagal menghubungi server. Silakan coba lagi.';
      });

      _shake();
    }
  }

  void _showApiBottomSheet() {
    String tempEnv = ApiConfig.selectedEnv;
    final ipCtrl = TextEditingController(text: ApiConfig.customIp);
    final portCtrl = TextEditingController(text: ApiConfig.customPort);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        color: Color(0xFF2B5A41),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Konfigurasi Server',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B5A41),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...['Production', 'Staging', 'Custom'].map((env) {
                    final isSelected = tempEnv == env;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() => tempEnv = env),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F1EC)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2B5A41)
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFF2B5A41)
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      env,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF2B5A41)
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (env != 'Custom')
                                      Text(
                                        env == 'Production'
                                            ? 'Server utama'
                                            : 'Server pengujian',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (tempEnv == 'Custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: ipCtrl,
                      decoration: InputDecoration(
                        labelText: 'IP Address',
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.computer, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2B5A41),
                            width: 1.5,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: portCtrl,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        hintText: '8000',
                        prefixIcon: const Icon(
                          Icons.settings_ethernet,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2B5A41),
                            width: 1.5,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ApiConfig.saveSetting(
                          tempEnv,
                          ip: ipCtrl.text.trim(),
                          port: portCtrl.text.trim(),
                        );

                        if (!mounted) return;

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Server: ${ApiConfig.baseUrl}'),
                            backgroundColor: const Color(0xFF2B5A41),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5A41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_checkingSavedLogin) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2B5A41)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // ─── GREEN HEADER BACKGROUND ─────────────────────────
            Container(
              height: size.height * 0.40,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2B5A41),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onLongPress: _showApiBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Devora\nSMAN 4 JEMBER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Selamat Datang\nKembali',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk untuk melanjutkan\nke perpustakaan digital.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── FLOATING LOGIN CARD ─────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.32,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? 10 * ((_shakeAnimation.value * 5) % 2 < 1 ? 1 : -1)
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2B5A41,
                            ).withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_generalError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFCDD2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFE53935),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _generalError!,
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Email Field
                          CustomTextField(
                            label: 'Email atau Username',
                            hint: 'Masukkan alamat email',
                            controller: _emailCtrl,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            onChanged: _clearErrors,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kata Sandi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Lupa?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B5A41),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: '',
                            hint: '••••••••',
                            controller: _passwordCtrl,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            errorText: _passwordError,
                            onChanged: _clearErrors,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade400,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isLoading
                                ? null
                                : () => setState(
                                    () => _keepSignedIn = !_keepSignedIn,
                                  ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _keepSignedIn,
                                      activeColor: const Color(0xFF2B5A41),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: _isLoading
                                          ? null
                                          : (value) => setState(
                                              () =>
                                                  _keepSignedIn = value ?? true,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Keep me signed in',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Tetap login walaupun aplikasi ditutup dari recent apps.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF7A7A7A),
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B5A41),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Masuk Sekarang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── SECONDARY ACTIONS ───────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Belum punya akun?',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2B5A41),
                              side: const BorderSide(
                                color: Color(0xFF2B5A41),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Daftar Umum',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ClaimLookupScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F1EC),
                              foregroundColor: const Color(0xFF2B5A41),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Aktivasi Siswa/Guru',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
