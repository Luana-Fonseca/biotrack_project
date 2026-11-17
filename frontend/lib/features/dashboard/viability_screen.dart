import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/charts.dart';
import 'dashboard_models.dart';
import 'dashboard_provider.dart';

const _fuelColors = {
  'DIESEL_S10': Color(0xFFF59E0B),
  'DIESEL_B12': Color(0xFFDC2626),
  'GASOLINA': Color(0xFFDB2777),
  'ETANOL': Color(0xFF7C3AED),
};

class ViabilityScreen extends StatefulWidget {
  const ViabilityScreen({super.key});

  @override
  State<ViabilityScreen> createState() => _ViabilityScreenState();
}

class _ViabilityScreenState extends State<ViabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DashboardProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final p = context.palette;
    final summary = provider.summary;
    final avgPerCalc = (summary != null && summary.totalCalculations > 0) ? summary.totalEconomyBrl / summary.totalCalculations : 0.0;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: provider.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: BioIcon('chev-l', size: 20, color: p.gray),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Viabilidade Econômica', style: AppText.inter(size: 22, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text('Todos os combustíveis vs Biometano — quanto você economiza', style: AppText.inter(size: 13, color: p.gray)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.verde, AppColors.verdeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ECONOMIA TOTAL', style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: Colors.white.withOpacity(0.75), letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text(fmtBRL(summary?.totalEconomyBrl ?? 0), style: AppText.mono(size: 40, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Evolução mensal', style: AppText.inter(size: 16, weight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 16),
                  BioLineChart(
                    values: provider.trend.map((t) => t.economyBrl).toList(),
                    labels: provider.trend.map((t) => t.label).toList(),
                    color: AppColors.verde,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _statCard(p, 'MÉDIA POR CÁLCULO', fmtBRL(avgPerCalc), AppColors.azul)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard(p, 'CÁLCULOS', '${summary?.totalCalculations ?? 0}', AppColors.verdeDark)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Combustível a combustível', style: AppText.inter(size: 16, weight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 4),
                  Text('Cada combustível da calculadora comparado com o Biometano, com base nos seus cálculos.',
                      style: AppText.inter(size: 12.5, color: p.gray)),
                  const SizedBox(height: 14),
                  ...provider.fuelViability.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _fuelViabilityCard(p, f),
                      )),
                ],
              ),
      ),
    );
  }

  Widget _fuelViabilityCard(AppPalette p, FuelViability f) {
    final color = _fuelColors[f.fuelType] ?? AppColors.gray;
    final hasData = f.calculations > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: BioIcon('gas', size: 16, color: color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(f.fuelLabel, style: AppText.inter(size: 14.5, weight: FontWeight.w700, color: p.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: p.border.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
                child: Text('${f.calculations} cálculo${f.calculations == 1 ? '' : 's'}',
                    style: AppText.mono(size: 10, weight: FontWeight.w600, color: p.gray)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            Text('Ainda sem cálculos com ${f.fuelLabel.toLowerCase()} — o comparativo aparece assim que você registrar um.',
                style: AppText.inter(size: 12, color: p.gray2))
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ECONOMIA VS BIOMETANO', style: AppText.mono(size: 9, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      Text(fmtBRL(f.economyBrl), style: AppText.mono(size: 16, weight: FontWeight.w700, color: AppColors.verdeDark)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CO₂ EVITADO', style: AppText.mono(size: 9, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      Text('${fmtNumber(f.co2AvoidedKg, 0)} kg', style: AppText.mono(size: 16, weight: FontWeight.w700, color: p.ink)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statCard(AppPalette p, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(value, style: AppText.mono(size: 17, weight: FontWeight.w700, color: color, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}
