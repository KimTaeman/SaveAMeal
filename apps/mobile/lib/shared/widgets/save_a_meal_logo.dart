import 'package:flutter/material.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

class SaveAMealLogo extends StatelessWidget {
  const SaveAMealLogo({super.key, this.size = 64.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(
        painter: _PinPainter(pin: cs.primary, dot: ac.warning),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({required this.pin, required this.dot});

  final Color pin;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = size.width * 0.41;
    final cy = r + size.width * 0.04;

    final stroke = Paint()
      ..color = pin
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(Offset(cx, cy), r, stroke);

    final path = Path()
      ..moveTo(cx - r * 0.68, cy + r * 0.72)
      ..quadraticBezierTo(cx - r * 0.1, size.height * 0.88, cx, size.height)
      ..moveTo(cx + r * 0.68, cy + r * 0.72)
      ..quadraticBezierTo(cx + r * 0.1, size.height * 0.88, cx, size.height);
    canvas.drawPath(path, stroke);

    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
