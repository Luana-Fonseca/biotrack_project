import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import 'calculator_provider.dart';
import 'history_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<CalculatorProvider>().lastResult;
    final p = context.palette;

    if (result == null) {
      return Scaffold(backgroundColor: p.bg, body: const Center(child: Text('Nenhum resultado disponível.')));
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.verde, AppColors.verdeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _headerIconButton(context, 'chev-l', () => Navigator.of(context).pop()),
                    ),
                    const SizedBox(height: 14),
                    Text('CO₂ EVITADO NESTE CÁLCULO',
                        style: AppText.mono(size: 11, weight: FontWeight.w700, color: Colors.white.withOpacity(0.85), letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Text(fmtNumber(result.co2Kg), style: AppText.mono(size: 52, weight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                    const SizedBox(height: 2),
                    Text('quilogramas de CO₂', style: AppText.inter(size: 13, color: Colors.white.withOpacity(0.85))),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BioIcon('check', size: 13, color: Colors.white, strokeWidth: 2.5),
                          const SizedBox(width: 6),
                          Text('Cálculo salvo no histórico', style: AppText.inter(size: 12, weight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  children: [
                    if (result.anomaly) ...[
                      _anomalyBanner(p, result.anomalyReason ?? 'Este cálculo está fora do seu padrão habitual.'),
                      const SizedBox(height: 12),
                    ],
                    _statCard(
                      p,
                      icon: 'tree',
                      iconBg: AppColors.verde.withOpacity(0.14),
                      iconColor: AppColors.verdeDark,
                      label: 'Árvores salvas',
                      value: '${result.treesEquivalent}',
                      unit: 'árvores/ano',
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      p,
                      icon: 'money',
                      iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Economia estimada',
                      value: fmtBRL(result.economyBrl),
                      unit: 'em combustível',
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      p,
                      icon: 'route',
                      iconBg: AppColors.azul.withOpacity(0.1),
                      iconColor: AppColors.azul,
                      label: 'Quilometragem',
                      value: fmtNumber(result.distanceKm, result.distanceKm < 100 ? 1 : 0),
                      unit: result.distanceEstimated ? 'km estimados nesta rota' : 'km nesta rota',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Novo cálculo', icon: 'plus', iconLeading: true, onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      child: Text('Ver histórico completo', style: AppText.inter(size: 13.5, weight: FontWeight.w600, color: AppColors.azul)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _anomalyBanner(AppPalette p, String reason) {
    const amber = Color(0xFFF59E0B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: amber.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: amber.withOpacity(0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BioIcon('alert', size: 18, color: amber, strokeWidth: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consumo fora do padrão', style: AppText.inter(size: 13, weight: FontWeight.w700, color: const Color(0xFFB45309))),
                const SizedBox(height: 3),
                Text(reason, style: AppText.inter(size: 11.5, color: p.ink.withOpacity(0.8), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(BuildContext context, String icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
        child: Center(child: BioIcon(icon, size: 17, color: Colors.white, strokeWidth: 2.2)),
      ),
    );
  }

  Widget _statCard(
    AppPalette p, {
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: BioIcon(icon, size: 20, color: iconColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.inter(size: 11.5, color: p.gray)),
                const SizedBox(height: 3),
                Text(value, style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.3)),
                Text(unit, style: AppText.inter(size: 10.5, color: p.gray2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
