import 'package:flutter/material.dart';
import 'dart:math' as math;

class PokerLogo extends StatefulWidget {
  final double size;

  const PokerLogo({
    super.key,
    this.size = 300,
  });

  @override
  State<PokerLogo> createState() => _PokerLogoState();
}

class _PokerLogoState extends State<PokerLogo> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background pattern
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                  size: Size(widget.size, widget.size),
                ),
              );
            },
          ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated card suits
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_scaleController.value * 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSuit(Icons.favorite, Colors.red),
                        _buildSuit(Icons.spa, Colors.white),
                        _buildSuit(Icons.eco, Colors.white),
                        _buildSuit(Icons.diamond, Colors.red),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Animated text
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: const Text(
                      'POKEROLA',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          BoxShadow(
                            color: Colors.red,
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuit(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        icon,
        color: color,
        size: 32,
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < 8; i++) {
      final radius = (size.width / 3) * (1 + i * 0.1);
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );
    }

    // Draw diagonal lines
    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi) / 6;
      canvas.drawLine(
        Offset(
          centerX + math.cos(angle) * size.width,
          centerY + math.sin(angle) * size.height,
        ),
        Offset(
          centerX - math.cos(angle) * size.width,
          centerY - math.sin(angle) * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
