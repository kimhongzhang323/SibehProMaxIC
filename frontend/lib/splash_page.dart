import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _stackController;

  @override
  void initState() {
    super.initState();
    _stackController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _stackController.dispose();
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
            // Card stack animation
            Center(
              child: AnimatedBuilder(
                animation: _stackController,
                builder: (context, child) {
                  return _CardStack(progress: _stackController.value);
                },
              ),
            ),
            // Redirecting text
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

class _CardStack extends StatelessWidget {
  final double progress;
  const _CardStack({required this.progress});

  @override
  Widget build(BuildContext context) {
    const cardWidth = 14.0 * 16.0; // 14em in pixels (224px)
    const cardHeight = cardWidth * 0.63; // ID card aspect ratio ~1.6:1
    const stackHeight = 32.0 * 16.0; // 32em in pixels (512px)
    const stackSpacing = 0.15; // 15% spacing

    return SizedBox(
      width: cardWidth,
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _StackCard(
            index: 0,
            progress: progress,
            topOffset: stackSpacing,
            delay: 0.0,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          ),
          _StackCard(
            index: 1,
            progress: progress,
            topOffset: 0.0,
            delay: 0.05,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          ),
          _StackCard(
            index: 2,
            progress: progress,
            topOffset: -stackSpacing,
            delay: 0.10,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            showIcon: true,
          ),
        ],
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  final int index;
  final double progress;
  final double topOffset;
  final double delay;
  final double cardWidth;
  final double cardHeight;
  final bool showIcon;

  const _StackCard({
    required this.index,
    required this.progress,
    required this.topOffset,
    required this.delay,
    required this.cardWidth,
    required this.cardHeight,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardSize = cardWidth;

    // Calculate animation progress with delay
    final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
    final t = adjustedProgress;

    // 3D transform: rotateX(45deg) rotateZ(-45deg)
    final rotateX = 45.0 * pi / 180;
    final rotateZ = -45.0 * pi / 180;

    // Z translation based on animation keyframes
    double translateZ = 0;
    double opacity = 1.0;

    if (t <= 0.11) {
      // 0-11%: ease-in-out, translateZ(0)
      final localT = t / 0.11;
      translateZ = 0;
      opacity = 1.0;
    } else if (t <= 0.34) {
      // 11-34%: ease-in, translateZ(0.125em) to translateZ(-12em), fade out
      final localT = (t - 0.11) / (0.34 - 0.11);
      translateZ = lerpDouble(0.125 * 16, -12 * 16, localT)!;
      opacity = 1.0 - localT;
    } else if (t <= 0.48) {
      // 34-48%: linear, translateZ(12em), opacity 0
      final localT = (t - 0.34) / (0.48 - 0.34);
      translateZ = lerpDouble(-12 * 16, 12 * 16, localT)!;
      opacity = 0.0;
    } else if (t <= 0.57) {
      // 48-57%: ease-out, translateZ(12em) to translateZ(0), fade in
      final localT = (t - 0.48) / (0.57 - 0.48);
      translateZ = lerpDouble(12 * 16, 0, localT)!;
      opacity = localT;
    } else if (t <= 0.61) {
      // 57-61%: ease-in-out, translateZ(0) to translateZ(-1.8em)
      final localT = (t - 0.57) / (0.61 - 0.57);
      translateZ = lerpDouble(0, -1.8 * 16, localT)!;
      opacity = 1.0;
    } else if (t <= 0.74) {
      // 61-74%: ease-in-out, translateZ(-1.8em) to translateZ(1.8em/3)
      final localT = (t - 0.61) / (0.74 - 0.61);
      translateZ = lerpDouble(-1.8 * 16, 1.8 * 16 / 3, localT)!;
      opacity = 1.0;
    } else if (t <= 0.87) {
      // 74-87%: ease-in-out, translateZ(1.8em/3) to translateZ(-1.8em/9)
      final localT = (t - 0.74) / (0.87 - 0.74);
      translateZ = lerpDouble(1.8 * 16 / 3, -1.8 * 16 / 9, localT)!;
      opacity = 1.0;
    } else {
      // 87-100%: ease-in-out, translateZ(-1.8em/9) to translateZ(0)
      final localT = (t - 0.87) / (1.0 - 0.87);
      translateZ = lerpDouble(-1.8 * 16 / 9, 0, localT)!;
      opacity = 1.0;
    }

    // Calculate top position with spacing
    final stackHeight = 32.0 * 16.0;
    final topPosition = (stackHeight * topOffset) + (stackHeight - cardHeight) / 2;

    return Positioned(
      left: (cardSize - cardWidth) / 2,
      top: topPosition,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(rotateX)
            ..rotateZ(rotateZ)
            ..translate(0, 0, translateZ),
          child: _CardWidget(
            width: cardWidth,
            height: cardHeight,
            showIcon: showIcon,
          ),
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool showIcon;
  const _CardWidget({
    required this.width,
    required this.height,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = width * 0.075; // 7.5% border radius

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.08),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(-8, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.0647, size.height * 0.4353) // 1.03553/16 * size
      ..cubicTo(
        size.width * 0.0647, size.height * 0.5328, // C(0, 8.52678)
        size.width * 0.0, size.height * 0.5328, // 0, 8.52678
        size.width * 0.0, size.height * 0.5966, // 0, 9.46447
      )
      ..cubicTo(
        size.width * 0.0, size.height * 0.8125, // 0, 11.4535
        size.width * 0.216, size.height * 1.0, // 1.54648, 13
        size.width * 0.216, size.height * 1.0, // 3.45416, 13
      )
      ..cubicTo(
        size.width * 0.2585, size.height * 1.0, // 4.1361, 13
        size.width * 0.3002, size.height * 0.9985, // 4.80278, 12.7981
        size.width * 0.3356, size.height * 0.7762, // 5.37019, 12.4199
      )
      ..lineTo(size.width * 0.4453, size.height * 0.7031) // 7.125, 11.25
      ..lineTo(size.width * 0.375, size.height * 0.9375) // 6, 15
      ..lineTo(size.width * 0.375, size.height * 1.0) // 6, 16
      ..lineTo(size.width * 0.625, size.height * 1.0) // 10, 16
      ..lineTo(size.width * 0.625, size.height * 0.9375) // 10, 15
      ..lineTo(size.width * 0.5547, size.height * 0.7031) // 8.875, 11.25
      ..lineTo(size.width * 0.6644, size.height * 0.7762) // 10.6298, 12.4199
      ..cubicTo(
        size.width * 0.6998, size.height * 0.9985, // 11.1972, 12.7981
        size.width * 0.7415, size.height * 1.0, // 11.8639, 13
        size.width * 0.784, size.height * 1.0, // 12.5458, 13
      )
      ..cubicTo(
        size.width * 0.784, size.height * 1.0, // 14.4535, 13
        size.width * 1.0, size.height * 0.8125, // 16, 11.4535
        size.width * 1.0, size.height * 0.5966, // 16, 9.54584
      )
      ..cubicTo(
        size.width * 1.0, size.height * 0.5328, // 16, 9.46447
        size.width * 0.9353, size.height * 0.5328, // 15.6275, 8.52678
        size.width * 0.9353, size.height * 0.4353, // 14.9645, 7.62751
      )
      ..lineTo(size.width * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
