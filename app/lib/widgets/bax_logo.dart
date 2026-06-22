import 'package:flutter/material.dart';
import '../theme.dart';

class BaxLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const BaxLogo({super.key, this.size = 48, this.showText = true});

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
            'ON',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.28),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opportunities',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                    color: BaxColors.text,
                  ),
                ),
                Text(
                  'NAMIBIA',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: BaxColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
