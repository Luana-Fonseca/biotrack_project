import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../learning/learning_provider.dart';
import '../learning/trilha_detail_screen.dart';
import 'dashboard_models.dart';
import 'dashboard_provider.dart';

class ExplorerDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitch;

  const ExplorerDashboardScreen({super.key, required this.onSwitch});

  @override
  State<ExplorerDashboardScreen> createState() =>
      _ExplorerDashboardScreenState();
}

class ExplorerAchievement {
  final String icon;
  final Color color;
  final String label;
  final bool unlocked;

  ExplorerAchievement(
      {required this.icon,
      required this.color,
      required this.label,
      required this.unlocked});
}

class _ExplorerDashboardScreenState extends State<ExplorerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<LearningProvider>().loadTrilhas();
    });
  }

  List<ExplorerAchievement> _achievements(DashboardSummary? s) {
    return [
      ExplorerAchievement(
          icon: 'flame',
          color: const Color(0xFFF59E0B),
          label: 'Primeira ton',
          unlocked: (s?.totalCo2Kg ?? 0) >= 1000),
      ExplorerAchievement(
          icon: 'tree',
          color: AppColors.verdeDark,
          label: '100 árvores',
          unlocked: (s?.totalTrees ?? 0) >= 100),
      ExplorerAchievement(
          icon: 'trophy',
          color: const Color(0xFF9333EA),
          label: 'Top 500',
          unlocked: (s?.rank ?? 0) > 0 && (s!.rank) <= 500),
      ExplorerAchievement(
          icon: 'award',
          color: AppColors.azul,
          label: 'Trilha completa',
          unlocked: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final learning = context.watch<LearningProvider>();
    final p = context.palette;
    final summary = provider.summary;
    final achievements = _achievements(summary);
    final actuallyUnlocked = achievements.where((a) => a.unlocked).length;
    final inProgress = learning.trilhas
        .where((t) => t.progressPercent > 0 && t.progressPercent < 100)
        .toList();

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Perfil explorador',
                          style: AppText.inter(size: 12.5, color: p.gray)),
                      const SizedBox(height: 2),
                      Text('Explorar',
                          style: AppText.inter(
                              size: 26,
                              weight: FontWeight.w700,
                              color: AppColors.azul,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: widget.onSwitch,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: p.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Operacional',
                            style: AppText.inter(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: p.ink)),
                        const SizedBox(width: 4),
                        BioIcon('chev-r', size: 12, color: p.ink),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.azul, AppColors.azulDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IMPACTO GLOBAL · VOCÊ',
                        style: AppText.mono(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: AppColors.verde,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text('#${summary?.rank ?? 0}',
                        style: AppText.mono(
                            size: 40,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 4),
                    Text(
                      'entre ${_fmtK(summary?.totalUsers ?? 0)} usuários no Brasil',
                      style: AppText.inter(
                          size: 12.5, color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.15), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: _heroStat(
                                'STREAK', '${summary?.streakDays ?? 0} dias')),
                        Expanded(
                            child: _heroStat('XP', _fmtK(summary?.xp ?? 0))),
                        Expanded(
                            child: _heroStat('BADGES', '$actuallyUnlocked')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CONQUISTAS',
                      style: AppText.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          color: p.gray,
                          letterSpacing: 0.4)),
                  Text('VER TODAS',
                      style: AppText.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.verdeDark,
                          letterSpacing: 0.4)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) =>
                      _achievementCard(p, achievements[i]),
                ),
              ),
              const SizedBox(height: 24),
              Text('CONTINUE APRENDENDO',
                  style: AppText.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      color: p.gray,
                      letterSpacing: 0.4)),
              const SizedBox(height: 12),
              if (inProgress.isEmpty)
                Text('Nenhuma trilha em andamento ainda.',
                    style: AppText.inter(size: 13, color: p.gray))
              else
                ...inProgress.map((t) => InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TrilhaDetailScreen(trilha: t))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                      color: AppColors.verde.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                      child: BioIcon(t.icon,
                                          size: 16,
                                          color: AppColors.verdeDark)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(t.title,
                                        style: AppText.inter(
                                            size: 13.5,
                                            weight: FontWeight.w600,
                                            color: AppColors.azul))),
                                Text('${t.progressPercent}%',
                                    style: AppText.mono(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.verdeDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                  value: t.progressPercent / 100,
                                  minHeight: 5,
                                  backgroundColor: p.border,
                                  color: AppColors.verde),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtK(num value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.mono(
                size: 9.5,
                weight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(value,
            style: AppText.mono(
                size: 15, weight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _achievementCard(AppPalette p, ExplorerAchievement a) {
    final color = a.unlocked ? a.color : p.gray3;
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: BioIcon(a.icon, size: 16, color: color)),
          ),
          const SizedBox(height: 6),
          Text(a.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppText.inter(
                  size: 10,
                  weight: FontWeight.w600,
                  color: p.ink,
                  height: 1.15)),
        ],
      ),
    );
  }
}
