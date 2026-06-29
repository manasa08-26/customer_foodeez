import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'customer_logo.dart';

/// Auth screen branding — theme-aware customer logo.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    this.compact = false,
    this.subtitle = 'CUSTOMER APP',
  });

  final bool compact;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.adaptive;
    final accent = colors.primaryColor;

    return Column(
      children: [
        CustomerLogo.auth(compact: compact),
        SizedBox(height: compact ? 14 : 18),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 10.5 : 11,
            fontWeight: FontWeight.w700,
            color: accent.withValues(alpha: 0.62),
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }
}
