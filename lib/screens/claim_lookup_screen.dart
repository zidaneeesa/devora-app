import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'claim_activate_screen.dart';

class ClaimLookupScreen extends StatefulWidget {
  const ClaimLookupScreen({super.key});

  @override
  State<ClaimLookupScreen> createState() => _ClaimLookupScreenState();
}

class _ClaimLookupScreenState extends State<ClaimLookupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nisNipCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  late final AnimationController _shakeController;
  late final AnimationController _fadeController;

  late final Animation<double> _shakeAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Color _primary = Color(0xFF1A3C2A);
  static const Color _primaryLight = Color(0xFF2B5A41);
  static const Color _accent = Color(0xFFD4E8D9);
  static const Color _surface = Color(0xFFF4F7F5);
  static const Color _inputBg = Color(0xFFF1F4F2);
  static const Color _textPrimary = Color(0xFF1A1D1B);
  static const Color _textSecondary = Color(0xFF6B7770);

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _nisNipCtrl.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final nomorInduk = _nisNipCtrl.text.trim();

    FocusScope.of(context).unfocus();

    if (nomorInduk.isEmpty) {
      _showError('Masukkan NIS atau NIP Anda');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final res = await ApiService.claimLookup(nomorInduk);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (res['status'] == 200) {
        final responseData = res['data'];

        final memberData = responseData is Map && responseData['data'] != null
            ? responseData['data']
            : responseData;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClaimActivateScreen(memberData: memberData),
          ),
        );
      } else {
        final responseData = res['data'];
        final message = responseData is Map && responseData['message'] != null
            ? responseData['message'].toString()
            : 'Data tidak ditemukan';

        _showError(message);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showError('Gagal menghubungi server. Silakan coba lagi.');
    }
  }

  void _showError(String message) {
    setState(() => _errorMsg = message);
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double headerHeight =
        (size.height * 0.35).clamp(255.0, 320.0).toDouble();

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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Stack(
                  children: [
                    _buildHeader(headerHeight),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        headerHeight - 46,
                        20,
                        32,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildFormCard(),
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
          colors: [
            _primary,
            _primaryLight,
          ],
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
            right: -35,
            top: 28,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -45,
            bottom: 18,
            child: Container(
              height: 115,
              width: 115,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => Navigator.pop(context),
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
                      'Aktivasi\nAkun Anggota',
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
                      'Khusus Siswa dan Guru SMAN 4 Jember',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
            _buildInfoBox(),
            if (_errorMsg != null) ...[
              const SizedBox(height: 18),
              _buildErrorBox(),
            ],
            const SizedBox(height: 22),
            _buildInputField(),
            const SizedBox(height: 28),
            _buildSubmitButton(),
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
            Icons.badge_outlined,
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
                'Cari Data Anda',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Masukkan nomor induk yang terdaftar',
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

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryLight.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryLight.withValues(alpha: 0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _primaryLight,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gunakan NIS untuk siswa atau NIP untuk guru. Pastikan nomor yang dimasukkan sesuai dengan data sekolah.',
              style: TextStyle(
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
        border: Border.all(
          color: const Color(0xFFFFCDD2),
        ),
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
              _errorMsg ?? '',
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

  Widget _buildInputField() {
    return TextField(
      controller: _nisNipCtrl,
      enabled: !_isLoading,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.search,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onSubmitted: (_) {
        if (!_isLoading) _lookup();
      },
      onChanged: (_) {
        if (_errorMsg != null) {
          setState(() => _errorMsg = null);
        } else {
          setState(() {});
        }
      },
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: 'Nomor Induk (NIS/NIP)',
        hintText: 'Masukkan nomor induk Anda',
        prefixIcon: const Icon(
          Icons.badge_outlined,
          color: _primaryLight,
        ),
        suffixIcon: _nisNipCtrl.text.isEmpty || _isLoading
            ? null
            : IconButton(
                onPressed: () {
                  _nisNipCtrl.clear();
                  setState(() => _errorMsg = null);
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: _textSecondary,
                  size: 20,
                ),
              ),
        filled: true,
        fillColor: _inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        labelStyle: const TextStyle(
          color: _textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: _textSecondary.withValues(alpha: 0.75),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: _primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFE53935),
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _lookup,
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
                      'Cari Data Saya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.search_rounded,
                      size: 21,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}