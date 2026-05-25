import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _devoraController;
  late AnimationController _subtitleController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _devoraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _subtitleController,
            curve: Curves.easeOutCubic,
          ),
        );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    _logoController.forward();
    _devoraController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    await _subtitleController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _devoraController.dispose();
    _subtitleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _blurCircle(
              size: 220,
              color: const Color(0xFF2B5A41).withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: _blurCircle(
              size: 250,
              color: const Color(0xFF679B7B).withOpacity(0.10),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 122,
                      height: 122,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B5A41).withOpacity(0.22),
                            blurRadius: 35,
                            spreadRadius: 3,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo-sman4-jember.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                _DevoraNetflixText(animation: _devoraController),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: const Text(
                      'E-Library SMAN 4 Jember',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.25;
                        final value = (_loadingController.value - delay).clamp(
                          0.0,
                          1.0,
                        );

                        final scale = 0.7 + (value * 0.45);
                        final opacity = 0.30 + (value * 0.70);

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2B5A41,
                              ).withOpacity(opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 38,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleOpacity,
              child: const Text(
                'SMA NEGERI 4 JEMBER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DevoraNetflixText extends StatelessWidget {
  final Animation<double> animation;

  const _DevoraNetflixText({required this.animation});

  double _interval(
    double progress,
    double start,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    if (progress <= start) return 0.0;
    if (progress >= end) return 1.0;

    final value = (progress - start) / (end - start);
    return curve.transform(value);
  }

  double _lerp(double start, double end, double value) {
    return start + ((end - start) * value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;

        final dFade = _interval(progress, 0.00, 0.22, curve: Curves.easeIn);

        final dMove = _interval(
          progress,
          0.22,
          0.55,
          curve: Curves.easeInOutCubic,
        );

        final dX = _lerp(0, -92, dMove);

        return SizedBox(
          width: 260,
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _letter(
                letter: 'D',
                x: dX,
                opacity: dFade,
                scale: _lerp(1.15, 1.0, dMove),
                color: const Color(0xFF1F2937),
              ),

              _animatedNextLetter(
                progress: progress,
                letter: 'E',
                finalX: -55,
                start: 0.48,
                end: 0.62,
                color: const Color(0xFF1F2937),
              ),

              _animatedNextLetter(
                progress: progress,
                letter: 'V',
                finalX: -17,
                start: 0.58,
                end: 0.72,
                color: const Color(0xFF2B5A41),
                glow: true,
              ),

              _animatedNextLetter(
                progress: progress,
                letter: 'O',
                finalX: 24,
                start: 0.68,
                end: 0.82,
                color: const Color(0xFF1F2937),
              ),

              _animatedNextLetter(
                progress: progress,
                letter: 'R',
                finalX: 64,
                start: 0.78,
                end: 0.92,
                color: const Color(0xFF1F2937),
              ),

              _animatedNextLetter(
                progress: progress,
                letter: 'A',
                finalX: 103,
                start: 0.86,
                end: 1.00,
                color: const Color(0xFF1F2937),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _animatedNextLetter({
    required double progress,
    required String letter,
    required double finalX,
    required double start,
    required double end,
    required Color color,
    bool glow = false,
  }) {
    final value = _interval(progress, start, end, curve: Curves.easeOutBack);

    final opacity = _interval(progress, start, end, curve: Curves.easeIn);

    final x = _lerp(finalX - 22, finalX, value);
    final scale = _lerp(0.75, 1.0, value);

    return _letter(
      letter: letter,
      x: x,
      opacity: opacity,
      scale: scale,
      color: color,
      glow: glow,
    );
  }

  Widget _letter({
    required String letter,
    required double x,
    required double opacity,
    required double scale,
    required Color color,
    bool glow = false,
  }) {
    return Transform.translate(
      offset: Offset(x, 0),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: glow
                      ? const Color(0xFF2B5A41).withOpacity(0.35)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: glow ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
