import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import 'register_verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Error states
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _generalError;

  // Shake animation
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _generalError != null) {
      setState(() {
        _nameError = null;
        _emailError = null;
        _phoneError = null;
        _passwordError = null;
        _generalError = null;
      });
    }
  }

  bool _validateForm() {
    bool valid = true;
    setState(() {
      _clearErrors();
      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = 'Nama wajib diisi';
        valid = false;
      }
      if (_emailCtrl.text.trim().isEmpty) {
        _emailError = 'Email wajib diisi';
        valid = false;
      } else if (!_emailCtrl.text.contains('@')) {
        _emailError = 'Format email tidak valid';
        valid = false;
      }

      if (_phoneCtrl.text.trim().isEmpty) {
        _phoneError = 'Nomor HP wajib diisi';
        valid = false;
      } else if (!RegExp(
        r'^(08|628|8)[0-9]{8,13}$',
      ).hasMatch(_phoneCtrl.text.trim())) {
        _phoneError = 'Format nomor HP tidak valid';
        valid = false;
      }

      if (_passwordCtrl.text.isEmpty) {
        _passwordError = 'Kata sandi diperlukan';
        valid = false;
      } else if (_passwordCtrl.text.length < 6) {
        _passwordError = 'Minimal 6 karakter';
        valid = false;
      }
    });
    return valid;
  }

  void _register() async {
    if (!_validateForm()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    final res = await ApiService.registerSendOtp(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['data']['message'] ?? 'OTP pendaftaran dikirim ke email',
          ),
          backgroundColor: const Color(0xFF2B5A41),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterVerifyOtpScreen(
            name: name,
            email: email,
            phone: phone,
            password: password,
          ),
        ),
      );
    } else {
      final data = res['data'];

      if (res['status'] == 422 && data['errors'] != null) {
        setState(() {
          final errors = data['errors'] as Map;

          if (errors.containsKey('name')) {
            _nameError = errors['name'][0];
          }

          if (errors.containsKey('email')) {
            _emailError = errors['email'][0];
          }

          if (errors.containsKey('phone')) {
            _phoneError = errors['phone'][0];
          }

          if (errors.containsKey('password')) {
            _passwordError = errors['password'][0];
          }
        });
      } else {
        setState(() {
          _generalError = data['message'] ?? 'Gagal mengirim OTP pendaftaran.';
        });
      }

      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // ─── GREEN HEADER BACKGROUND ─────────────────────────
            Container(
              height: size.height * 0.35,
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
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Buat Akun\nBaru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Pendaftaran keanggotaan umum.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── FLOATING REGISTER CARD ─────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.28,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? 10 * ((_shakeController.value * 5) % 2 < 1 ? 1 : -1)
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

                          CustomTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                            errorText: _nameError,
                            onChanged: _clearErrors,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Email',
                            hint: 'Masukkan email Anda',
                            controller: _emailCtrl,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            onChanged: _clearErrors,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Nomor Handphone',
                            hint: '08xxxxxxxxxx',
                            controller: _phoneCtrl,
                            prefixIcon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            errorText: _phoneError,
                            onChanged: _clearErrors,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Kata Sandi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: '',
                            hint: 'Minimal 6 karakter',
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
                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
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
                                : const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Akun akan aktif setelah verifikasi oleh admin.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
