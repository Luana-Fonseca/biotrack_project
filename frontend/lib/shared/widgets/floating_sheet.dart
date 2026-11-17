import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A centered, floating alternative to [showModalBottomSheet] — same "pick something from a
/// list" or "show details" use case, but presented as a rounded card floating over a dimmed
/// background instead of anchored to the bottom edge.
Future<T?> showFloatingSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 440,
}) {
  final p = context.palette;
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: p.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
        ),
        child: builder(dialogContext),
      ),
    ),
  );
}
