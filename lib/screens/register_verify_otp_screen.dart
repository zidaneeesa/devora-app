import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterVerifyOtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;

  const RegisterVerifyOtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<RegisterVerifyOtpScreen> createState() =>
      _RegisterVerifyOtpScreenState();
}

class _RegisterVerifyOtpScreenState extends State<RegisterVerifyOtpScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocuses = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _generalError;

  late final AnimationController _shakeController;
  late final AnimationController _entranceController;

  late final Animation<double> _shakeAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Color _primary = Color(0xFF1A3C2A);
  static const Color _primaryLight = Color(0xFF2B5A41);
  static const Color _accent = Color(0xFFE8F1EC);
  static const Color _surface = Color(0xFFF4F7F5);
  static const Color _inputBg = Color(0xFFF4F7F5);
  static const Color _textPrimary = Color(0xFF1A1D1B);
  static const Color _textSecondary = Color(0xFF6B7770);

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _entranceController.dispose();

    for (final controller in _otpCtrls) {
      controller.dispose();
    }

    for (final focus in _otpFocuses) {
      focus.dispose();
    }

    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((controller) => controller.text).join();

  bool get _isBusy => _isLoading || _isResending;

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final otp = _otpCode;

    if (otp.length != 6 ||
        _otpCtrls.any((controller) => controller.text.isEmpty)) {
      _showError('Masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final res = await ApiService.registerVerifyOtp(
        email: widget.email,
        phone: widget.phone,
        otp: otp,
      );

      debugPrint('VERIFY REGISTER OTP STATUS: ${res['status']}');
      debugPrint('VERIFY REGISTER OTP DATA: ${res['data']}');

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (res['status'] == 201 || res['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getMessage(
                res['data'],
                'Registrasi berhasil. Akun Anda menunggu persetujuan admin.',
              ),
            ),
            backgroundColor: _primaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        return;
      }

      _showError(
        _getMessage(res['data'], 'OTP tidak valid atau sudah kedaluwarsa.'),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showError('Gagal menghubungi server. Silakan coba lagi.');
    }
  }

  Future<void> _resendOtp() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isResending = true;
      _generalError = null;
    });

    try {
      final res = await ApiService.registerSendOtp(
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
      );

      if (!mounted) return;

      setState(() => _isResending = false);

      if (res['status'] == 200) {
        _clearOtp();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getMessage(res['data'], 'Kode OTP baru berhasil dikirim.'),
            ),
            backgroundColor: _primaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        _otpFocuses.first.requestFocus();
        return;
      }

      _showError(_getMessage(res['data'], 'Gagal mengirim ulang OTP.'));
    } catch (_) {
      if (!mounted) return;

      setState(() => _isResending = false);

      _showError('Gagal menghubungi server. Silakan coba lagi.');
    }
  }

  void _showError(String message) {
    setState(() => _generalError = message);
    _shakeController.forward(from: 0);
  }

  void _clearOtp() {
    for (final controller in _otpCtrls) {
      controller.clear();
    }

    setState(() => _generalError = null);
  }

  void _fillOtpFromText(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digits.length > 6 ? digits.substring(0, 6) : digits;

    for (int i = 0; i < 6; i++) {
      _otpCtrls[i].text = i < limitedDigits.length ? limitedDigits[i] : '';
    }

    if (limitedDigits.length >= 6) {
      FocusScope.of(context).unfocus();
    } else {
      _otpFocuses[limitedDigits.length].requestFocus();
    }

    setState(() => _generalError = null);
  }

  String _getMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return fallback;
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');

    if (parts.length != 2) {
      return email;
    }

    final name = parts[0];
    final domain = parts[1];

    if (name.isEmpty) {
      return '***@$domain';
    }

    if (name.length == 1) {
      return '${name[0]}***@$domain';
    }

    final start = name.substring(0, 2);
    return '$start***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double headerHeight = (size.height * 0.35)
        .clamp(255.0, 320.0)
        .toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    _buildHeader(headerHeight),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        headerHeight - 48,
                        20,
                        34,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildVerificationCard(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double headerHeight) {
    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: 28,
            child: Container(
              height: 125,
              width: 125,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: 18,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _isBusy ? null : () => Navigator.pop(context),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Verifikasi\nPendaftaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Masukkan kode OTP untuk menyelesaikan pendaftaran.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _primaryLight.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardHeader(),
            const SizedBox(height: 22),
            _buildEmailInfoBox(),
            if (_generalError != null) ...[
              const SizedBox(height: 18),
              _buildErrorBox(),
            ],
            const SizedBox(height: 24),
            _buildOtpFields(),
            const SizedBox(height: 28),
            _buildVerifyButton(),
            const SizedBox(height: 20),
            _buildResendOtp(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            color: _primaryLight,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cek Email Anda',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Masukkan 6 digit kode OTP',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryLight.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryLight.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _primaryLight,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kode OTP telah dikirim ke email ${_maskedEmail(widget.email)}. Jangan bagikan kode ini kepada siapa pun.',
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE53935),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _generalError ?? '',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final boxWidth = ((constraints.maxWidth - (gap * 5)) / 6).clamp(
          48.0,
          62.0,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final hasValue = _otpCtrls[index].text.isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
              child: SizedBox(
                width: boxWidth,
                height: 80,
                child: TextField(
                  controller: _otpCtrls[index],
                  focusNode: _otpFocuses[index],
                  enabled: !_isLoading,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  textInputAction: index == 5
                      ? TextInputAction.done
                      : TextInputAction.next,
                  maxLength: 6,
                  cursorHeight: 24,
                  cursorColor: _primaryLight,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: _primaryLight,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    filled: true,
                    fillColor: hasValue ? _accent : _inputBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: hasValue
                            ? _primaryLight.withValues(alpha: 0.45)
                            : const Color(0xFFCBEAD7),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _primaryLight,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onTap: () {
                    _otpCtrls[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _otpCtrls[index].text.length,
                    );
                  },
                  onChanged: (value) {
                    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

                    if (digits.length > 1) {
                      _fillOtpFromText(digits);
                      return;
                    }

                    if (_generalError != null) {
                      setState(() => _generalError = null);
                    } else {
                      setState(() {});
                    }

                    if (value.isNotEmpty && index < 5) {
                      _otpFocuses[index + 1].requestFocus();
                    }

                    if (value.isEmpty && index > 0) {
                      _otpFocuses[index - 1].requestFocus();
                    }

                    if (_otpCode.length == 6 &&
                        _otpCtrls.every(
                          (controller) => controller.text.isNotEmpty,
                        )) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  onSubmitted: (_) {
                    if (index == 5 && !_isLoading) {
                      _verifyOtp();
                    }
                  },
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          disabledBackgroundColor: _primaryLight.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 23,
                  width: 23,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  key: ValueKey('button_text'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verifikasi Pendaftaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.verified_rounded, size: 21),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResendOtp() {
    return Center(
      child: TextButton(
        onPressed: _isBusy ? null : _resendOtp,
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isResending
              ? Row(
                  key: const ValueKey('resending'),
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryLight,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mengirim ulang...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : RichText(
                  key: const ValueKey('resend_text'),
                  text: TextSpan(
                    text: 'Tidak menerima kode? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Kirim Ulang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
