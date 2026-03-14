import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class SpinWheelWidget extends ConsumerStatefulWidget {
  final void Function(int landedIndex) onSpinDone;

  const SpinWheelWidget({super.key, required this.onSpinDone});

  @override
  ConsumerState<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends ConsumerState<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentAngle = 0.0;
  double _beginAngle = 0.0;
  double _endAngle = 0.0;
  int _targetIndex = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _controller.addListener(() {
      final t = Curves.decelerate.transform(_controller.value);
      setState(() {
        _currentAngle = _beginAngle + (_endAngle - _beginAngle) * t;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isSpinning = false;
        widget.onSpinDone(_targetIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void spin(List<CardEntry> entries) {
    if (_isSpinning || entries.isEmpty) return;

    final rng = Random();
    // Land on a random segment
    _targetIndex = rng.nextInt(entries.length);
    final segmentAngle = (2 * pi) / entries.length;

    final extraRotations = 5 + rng.nextInt(6);
    
    // Painter starts at -pi/2 (top). Needle is at the TOP (0 relative to top).
    // Target segment center relative to the wheel's 0:
    final targetCenter = (segmentAngle * _targetIndex) + (segmentAngle / 2);
    
    // We want the target center to end up exactly at the needle (top center).
    // So the final angle (modulo 2pi) should be (0 - targetCenter).
    final targetOffset = -targetCenter;
    
    // Calculate how much we need to rotate from current angle to hit targetOffset
    final currentOffset = _currentAngle % (2 * pi);
    double delta = targetOffset - currentOffset;
    if (delta <= 0) {
      delta += 2 * pi;
    }
    
    final landingAngle = (2 * pi * extraRotations) + delta;

    _beginAngle = _currentAngle;
    _endAngle = _beginAngle + landingAngle;

    _isSpinning = true;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameCtrlProvider, (prev, next) {
      if (next.status == GameStatus.spinning && !_isSpinning) {
        spin(next.activeEntries.isNotEmpty ? next.activeEntries : next.entries);
      }
    });

    final game = ref.watch(gameCtrlProvider);
    // Show activeEntries during game (winners removed), show all when idle
    final displayEntries = game.isGameRunning || game.status == GameStatus.finished
        ? (game.activeEntries.isNotEmpty ? game.activeEntries : game.entries)
        : game.entries;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
        // ── Decoration ring (Background) ────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F111A), // Dark border ring
          ),
        ),
        // ── Wheel ────────────────────────────────────────────────────────────
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _WheelPainter(
              entries: displayEntries,
              angle: _currentAngle,
            ),
          ),
        ),
        // ── Center hub ─────────────────────────────────────────────────────
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.bgDarkHub,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        // ── Pointer pin (Top) ────────────────────────────────────────────────
        Positioned(
          top: -12,
          child: CustomPaint(
            painter: _NeedlePainter(),
            size: const Size(32, 32),
          ),
        ),
        // ── Empty state ──────────────────────────────────────────────────────
        if (displayEntries.isEmpty)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A2035),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino_rounded, color: AppTheme.accent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Add entries to\nstart playing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSub,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
      ],
        );
      },
    );
  }
}

// ── Wheel Painter ─────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<CardEntry> entries;
  final double angle;

  _WheelPainter({required this.entries, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = (2 * pi) / entries.length;
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle - pi / 2); // offset so top is start

    for (int i = 0; i < entries.length; i++) {
      // Draw segment
      paint.color = AppTheme.wheelColors[i % AppTheme.wheelColors.length];
      final startAngle = segAngle * i;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        segAngle,
        true,
        paint,
      );

      // Draw segment border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppTheme.bgDarkHub.withValues(alpha: 0.4)
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        segAngle,
        true,
        borderPaint,
      );

      // If there's only 1 entry, drawArc with a 2pi sweep may not draw the spoke.
      // Explicitly draw one spoke so a 1-item wheel visibly spins.
      if (entries.length == 1) {
        canvas.drawLine(
          Offset.zero,
          Offset(cos(startAngle) * radius, sin(startAngle) * radius),
          borderPaint,
        );
      }

      // Draw number text
      final textAngle = startAngle + segAngle / 2;
      final textRadius = radius * 0.68;
      final tx = cos(textAngle) * textRadius;
      final ty = sin(textAngle) * textRadius;

      canvas.save();
      canvas.translate(tx, ty);
      // Rotate text to be upright relative to the radius (facing outward)
      canvas.rotate(textAngle);

      final label = entries[i].label;
      final fontSize = entries.length <= 6
          ? 22.0
          : entries.length <= 12
              ? 17.0
              : 13.0;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer ring (Thick dark frame)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 14;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle || old.entries != entries;
}

// ── Needle Pointer Painter ─────────────────────────────────────────────────────
// Draws a classic spin-wheel needle:
//   ◄─── tip (left) points INTO the wheel
//   ────── body (white/gradient)
//   base (right, rounded) outside the wheel
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, h)             // tip (bottom center)
      ..lineTo(0, 0)                  // top left
      ..lineTo(w, 0)                  // top right
      ..close();

    // Shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Pin Body
    canvas.drawPath(
      path,
      Paint()..color = Colors.white,
    );

    // Neon Border
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.accentCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => false;
}

