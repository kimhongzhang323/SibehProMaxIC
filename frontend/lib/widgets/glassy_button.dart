import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassy, shimmering button inspired by the web effect.
/// - Soft translucent background with blur
/// - Subtle gradient overlay
/// - Animated shine pass across the surface
class GlassyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  State<GlassyButton> createState() => _GlassyButtonState();
}

class _GlassyButtonState extends State<GlassyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius;

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: widget.onPressed == null ? 1 : 1,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // Frosted background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: widget.height,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: borderRadius,
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
              // Static subtle overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.00),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Moving shine
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_shineController.value);
                    // Move from left (-0.8 width) to right (1.2 width)
                    final dx = lerpDouble(-0.8, 1.2, t)!;
                    return Transform.translate(
                      offset: Offset(dx * MediaQuery.of(context).size.width, 0),
                      child: child,
                    );
                  },
                  child: Transform(
                    transform: Matrix4.skewX(-12 * math.pi / 180),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.26),
                            Colors.white.withOpacity(0.0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
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

