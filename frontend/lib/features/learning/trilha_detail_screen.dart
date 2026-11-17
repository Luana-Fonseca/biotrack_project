import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import 'learning_models.dart';
import 'learning_provider.dart';
import 'module_content_screen.dart';

class TrilhaDetailScreen extends StatefulWidget {
  final TrilhaSummary trilha;

  const TrilhaDetailScreen({super.key, required this.trilha});

  @override
  State<TrilhaDetailScreen> createState() => _TrilhaDetailScreenState();
}

class _TrilhaDetailScreenState extends State<TrilhaDetailScreen> {
  List<ModuleSummary>? _modules;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final modules =
          await context.read<LearningProvider>().loadModules(widget.trilha.id);
      if (mounted) setState(() => _modules = modules);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final modules = _modules;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: modules == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: BioIcon('chev-l', size: 20, color: p.gray),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.trilha.coverImage != null &&
                      MediaQuery.sizeOf(context).width < 900)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Scales with the available width but stays within a
                        // comfortable band — big enough to read as a hero image,
                        // never tall enough to dominate the page.
                        final height =
                            (constraints.maxWidth * 0.22).clamp(150.0, 260.0);
                        return SizedBox(
                          width: double.infinity,
                          height: height,
                          child: Image.asset(
                              'assets/images/trilhas/${widget.trilha.coverImage}',
                              fit: BoxFit.cover),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: AppColors.verde.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                  child: BioIcon(widget.trilha.icon,
                                      size: 24, color: AppColors.verdeDark)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.trilha.title,
                                      style: AppText.inter(
                                          size: 19,
                                          weight: FontWeight.w700,
                                          color: p.ink)),
                                  const SizedBox(height: 4),
                                  Text(widget.trilha.description,
                                      style: AppText.inter(
                                          size: 12.5, color: p.gray)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ...modules.map((m) => InkWell(
                              onTap: () async {
                                await Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => ModuleContentScreen(
                                            module: m,
                                            trilhaId: widget.trilha.id)));
                                if (!mounted) return;
                                final refreshed = await context
                                    .read<LearningProvider>()
                                    .loadModules(widget.trilha.id);
                                if (mounted)
                                  setState(() => _modules = refreshed);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: p.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: p.border)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: m.completed
                                            ? AppColors.verde
                                            : p.border,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: m.completed
                                            ? const BioIcon('check',
                                                size: 14,
                                                color: Colors.white,
                                                strokeWidth: 2.5)
                                            : Text('${m.orderIndex + 1}',
                                                style: AppText.mono(
                                                    size: 12,
                                                    weight: FontWeight.w700,
                                                    color: p.gray)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.title,
                                              style: AppText.inter(
                                                  size: 14,
                                                  weight: FontWeight.w600,
                                                  color: p.ink)),
                                          Text('${m.durationMinutes} min',
                                              style: AppText.mono(
                                                  size: 11, color: p.gray2)),
                                        ],
                                      ),
                                    ),
                                    BioIcon('chev-r', size: 14, color: p.gray2),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
