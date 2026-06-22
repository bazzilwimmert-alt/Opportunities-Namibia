import 'package:flutter/material.dart';
import '../theme.dart';

// A faint, repeating diagonal watermark showing the signed-in member's
// identity. Screenshots cannot be hard-blocked on web/desktop/iOS, so any
// leaked image is traceable back to the account that captured it.
class Watermark extends StatelessWidget {
  final String label;
  final Widget child;
  const Watermark({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 40,
                    children: List.generate(
                      120,
                      (_) => Text(
                        label,
                        style: TextStyle(
                          color: BaxColors.muted.withValues(alpha: 0.06),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// A small banner reminding members that screenshots are prohibited.
class NoScreenshotNotice extends StatelessWidget {
  const NoScreenshotNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.no_photography, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Screenshots and screen recording are prohibited. Listings are '
              'watermarked with your account and a fine applies if detected.',
              style: TextStyle(color: BaxColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
