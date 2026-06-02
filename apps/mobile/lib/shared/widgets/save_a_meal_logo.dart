import 'package:flutter/material.dart';

class SaveAMealLogo extends StatelessWidget {
  const SaveAMealLogo({super.key, this.size = 64.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size * 1.3,
      fit: BoxFit.contain,
    );
  }
}
