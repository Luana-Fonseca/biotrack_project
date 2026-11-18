import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import 'learning_models.dart';
import 'learning_provider.dart';
import 'trilha_detail_screen.dart';

class TrilhasScreen extends StatefulWidget {
  const TrilhasScreen({super.key});

  @override
  State<TrilhasScreen> createState() => _TrilhasScreenState();
}

class _TrilhasScreenState extends State<TrilhasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<LearningProvider>().loadTrilhas());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: provider.loading && provider.trilhas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  Text('Trilhas',
                      style: AppText.inter(
                          size: 26,
                          weight: FontWeight.w700,
                          color: AppColors.azul,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Aprenda sobre descarbonização e ESG',
                      style: AppText.inter(size: 13, color: p.gray)),
                  const SizedBox(height: 20),
                  if (provider.error != null && provider.trilhas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          BioIcon('alert', size: 28, color: p.gray),
                          const SizedBox(height: 10),
                          Text(provider.error!,
                              textAlign: TextAlign.center,
                              style: AppText.inter(size: 13, color: p.gray)),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => context.read<LearningProvider>().loadTrilhas(),
                            child: const Text('Tentar de novo'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...provider.trilhas.map((t) => _CompactTrilhaCard(trilha: t)),
                ],
              ),
      ),
    );
  }
}

/// The original compact row: icon avatar, title, description, progress bar — used on desktop.
class _CompactTrilhaCard extends StatelessWidget {
  final TrilhaSummary trilha;

  const _CompactTrilhaCard({required this.trilha});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrilhaDetailScreen(trilha: trilha))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.verde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: BioIcon(trilha.icon,
                      size: 22, color: AppColors.verdeDark)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trilha.title,
                      style: AppText.inter(
                          size: 15, weight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 4),
                  Text(trilha.description,
                      style: AppText.inter(size: 12, color: p.gray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: trilha.progressPercent / 100,
                      backgroundColor: p.border,
                      color: AppColors.verde,
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${trilha.progressPercent}%',
                style: AppText.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.verdeDark)),
          ],
        ),
      ),
    );
  }
}
