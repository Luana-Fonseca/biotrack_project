import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'bio_icon.dart';

class BioTabItem {
  final String icon;
  final String label;

  const BioTabItem(this.icon, this.label);
}

class BioTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BioTabItem> items;

  const BioTabBar({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      key: const Key('SHELL_TAB_BAR'),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BioIcon(item.icon, size: 20, color: active ? AppColors.verde : p.gray2, strokeWidth: 2),
                      const SizedBox(height: 4),
                      Text(item.label, style: AppText.inter(size: 10.5, weight: FontWeight.w600, color: active ? AppColors.verde : p.gray2)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
