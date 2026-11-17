import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'bio_icon.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final String? icon;
  final bool iconLeading;
  final bool loading;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.icon, this.iconLeading = false, this.loading = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          disabledBackgroundColor: context.palette.gray3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null && iconLeading) ...[
                    BioIcon(icon!, size: 16, color: Colors.white, strokeWidth: 2.5),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppText.inter(size: 15, weight: FontWeight.w700, color: Colors.white)),
                  if (icon != null && !iconLeading) ...[
                    const SizedBox(width: 8),
                    BioIcon(icon!, size: 16, color: Colors.white, strokeWidth: 2.5),
                  ],
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: AppText.inter(size: 15, weight: FontWeight.w700, color: AppColors.azul)),
      ),
    );
  }
}
