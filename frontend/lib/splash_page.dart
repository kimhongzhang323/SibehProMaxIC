import 'dart:math';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _speederController;
  late final AnimationController _lineController;
  late final AnimationController _longLineController;

  @override
  void initState() {
    super.initState();
    _speederController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();

    _lineController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();

    _longLineController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _speederController.dispose();
    _lineController.dispose();
    _longLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: Stack(
          children: [
            _LongFazers(animation: _longLineController),
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_speederController, _lineController]),
                builder: (context, child) {
                  final t = _speederController.value;
                  final dx = sin(t * 2 * pi) * 3;
                  final dy = cos(t * 2 * pi) * 2;
                  final rotation = sin(t * 2 * pi) * 0.04; // slight wobble
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: rotation,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Slightly larger primary flyer
                    Transform.scale(scale: 1.05, child: _Speeder(animation: _lineController)),
                    // Secondary flyer layered for depth
                    Transform.translate(
                      offset: const Offset(-8, 6),
                      child: Transform.scale(
                        scale: 0.9,
                        child: _Speeder(opacity: 0.78, animation: _lineController),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Redirecting…',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Speeder extends StatelessWidget {
  final double opacity;
  final Animation<double> animation;
  const _Speeder({this.opacity = 1, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Trail lines
          Positioned(
            top: 30,
            left: 0,
            child: _ShortFazers(opacity: opacity, animation: animation),
          ),
          // Top stripe
          Positioned(
            top: 25,
            left: 45,
            child: Opacity(
              opacity: opacity,
              child: Container(
                height: 6,
                width: 35,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Body fill
          Positioned(
            top: 34,
            left: 55,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 100,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Triangle front
          Positioned(
            top: 28,
            left: 45,
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: const Size(100, 12),
                painter: _TrianglePainter(),
              ),
            ),
          ),
          // Head circle
          Positioned(
            right: -14,
            top: 18,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Face block
          Positioned(
            right: -6,
            top: 16,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: -0.6,
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.rotate(
                      angle: 0.6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            left: 60,
            child: Opacity(
              opacity: opacity,
              child: const Text(
                'Journey',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShortFazers extends StatelessWidget {
  final double opacity;
  final Animation<double> animation;
  const _ShortFazers({required this.opacity, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Stack(
          children: List.generate(4, (i) {
            final base = i * 3.0;
            final travel = (20 + i * 12) * v;
            final lineOpacity = (1 - v) * opacity;
            return Positioned(
              left: -travel - 10,
              top: base,
              child: Opacity(
                opacity: lineOpacity.clamp(0.0, 1.0),
                child: Container(
                  width: 30,
                  height: 1,
                  color: Colors.black,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _LongFazers extends StatelessWidget {
  final Animation<double> animation;
  const _LongFazers({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final configs = [
              const _LineConfig(topFactor: 0.2, speed: 1.2),
              const _LineConfig(topFactor: 0.4, speed: 1.5),
              const _LineConfig(topFactor: 0.6, speed: 1.0),
              const _LineConfig(topFactor: 0.8, speed: 1.8),
            ];
            return Stack(
              children: configs.map((c) {
                final travel = width * (1.5 * c.speed);
                final left = width - (animation.value * travel);
                final opacity = 1 - animation.value;
                return Positioned(
                  top: constraints.maxHeight * c.topFactor,
                  left: left,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Container(
                      width: width * 0.2,
                      height: 2,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _LineConfig {
  final double topFactor;
  final double speed;
  const _LineConfig({required this.topFactor, required this.speed});
}
