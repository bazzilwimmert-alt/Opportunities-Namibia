import 'package:flutter/material.dart';
import '../theme.dart';

class BaxLogo extends StatelessWidget {
  final double size;
  const BaxLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BaxColors.primary, BaxColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'B',
            style: TextStyle(
              fontSize: size * 0.58,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: size * 0.28),
        Text(
          'Bax',
          style: TextStyle(
            fontSize: size * 0.72,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: BaxColors.text,
          ),
        ),
      ],
    );
  }
}
