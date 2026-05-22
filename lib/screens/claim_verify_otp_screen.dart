import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ClaimVerifyOtpScreen extends StatefulWidget {
  final int memberId;
  final String email;
  final String password;

  const ClaimVerifyOtpScreen({
    super.key,
    required this.memberId,
    required this.email,
    required this.password,
  });

  @override
  State<ClaimVerifyOtpScreen> createState() => _ClaimVerifyOtpScreenState();
}

class _ClaimVerifyOtpScreenState extends State<ClaimVerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocuses = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _generalError;

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
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _verifyOtp() async {
    final otp = _otpCode;

    if (otp.length != 6) {
      setState(() => _generalError = 'Masukkan 6 digit kode OTP');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    final res = await ApiService.claimActivateVerifyOtp(
      memberId: widget.memberId,
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['data']['message'] ?? 'Akun berhasil diaktivasi'),
          backgroundColor: const Color(0xFF2B5A41),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _generalError = res['data']['message'] ?? 'OTP tidak valid';
      });
      _shakeController.forward(from: 0);
    }
  }

  void _resendOtp() async {
    setState(() {
      _isResending = true;
      _generalError = null;
    });

    final res = await ApiService.claimActivateSendOtp(
      memberId: widget.memberId,
      email: widget.email,
      password: widget.password,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['status'] == 200) {
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpFocuses[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['data']['message'] ?? 'Kode OTP baru telah dikirim',
          ),
          backgroundColor: const Color(0xFF2B5A41),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['data']['message'] ?? 'Gagal mengirim ulang OTP'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
                          'Verifikasi\nAktivasi',
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
                          'Masukkan kode OTP yang dikirim ke email Anda.',
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
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B5A41).withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1EC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBEAD7)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2B5A41),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kode dikirim ke:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4A7D60),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B5A41),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_generalError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
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

                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 8.0;
                          final boxWidth =
                              ((constraints.maxWidth - (gap * 5)) / 6).clamp(
                                38.0,
                                48.0,
                              );

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == 5 ? 0 : gap,
                                ),
                                child: SizedBox(
                                  width: boxWidth,
                                  height: 56,
                                  child: TextField(
                                    controller: _otpCtrls[index],
                                    focusNode: _otpFocuses[index],
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    cursorHeight: 24,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B5A41),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: const Color(0xFFF4F7F5),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBEAD7),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF2B5A41),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      // Handle paste OTP
                                      if (value.length > 1) {
                                        final digits = value.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        );

                                        for (int j = 0; j < 6; j++) {
                                          _otpCtrls[j].text = j < digits.length
                                              ? digits[j]
                                              : '';
                                        }

                                        final focusIdx = digits.length >= 6
                                            ? 5
                                            : digits.length;
                                        if (focusIdx < 6) {
                                          _otpFocuses[focusIdx].requestFocus();
                                        }

                                        setState(() => _generalError = null);

                                        if (digits.length >= 6) {
                                          FocusScope.of(context).unfocus();
                                        }

                                        return;
                                      }

                                      setState(() => _generalError = null);

                                      if (value.isNotEmpty && index < 5) {
                                        _otpFocuses[index + 1].requestFocus();
                                      }

                                      if (value.isEmpty && index > 0) {
                                        _otpFocuses[index - 1].requestFocus();
                                      }

                                      if (_otpCode.length == 6) {
                                        FocusScope.of(context).unfocus();
                                      }
                                    },
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
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
                                    'Verifikasi Aktivasi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.verified_rounded, size: 20),
                                ],
                              ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: RichText(
                            text: TextSpan(
                              text: 'Tidak menerima kode? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              children: [
                                TextSpan(
                                  text: _isResending
                                      ? 'Mengirim...'
                                      : 'Kirim Ulang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _isResending
                                        ? Colors.grey.shade400
                                        : const Color(0xFF2B5A41),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
