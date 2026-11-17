import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/charts.dart';
import '../reports/reports_screen.dart';
import 'dashboard_provider.dart';
import 'viability_screen.dart';

class OperationalDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitch;

  const OperationalDashboardScreen({super.key, required this.onSwitch});

  @override
  State<OperationalDashboardScreen> createState() => _OperationalDashboardScreenState();
}

class _OperationalDashboardScreenState extends State<OperationalDashboardScreen> {
  int _periodIndex = 1; // Sem / Mês / Tri / Ano
  static const _periods = ['Sem', 'Mês', 'Tri', 'Ano'];

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
    final fossilCo2 = summary?.totalCo2Kg ?? 0;
    final biometanoCo2 = fossilCo2 * 0.4;
    final maxCo2 = fossilCo2 <= 0 ? 1.0 : fossilCo2;
    final co2Delta = _percentDelta(provider.trend.map((t) => t.co2Kg).toList());
    final economyDelta = _percentDelta(provider.trend.map((t) => t.economyBrl).toList());

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: provider.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Perfil operacional', style: AppText.inter(size: 12.5, color: p.gray)),
                          const SizedBox(height: 2),
                          Text('Dashboard', style: AppText.inter(size: 26, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.5)),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: widget.onSwitch,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: p.border),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explorer', style: AppText.inter(size: 12.5, weight: FontWeight.w600, color: p.ink)),
                            const SizedBox(width: 4),
                            BioIcon('chev-r', size: 12, color: p.ink),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(_periods.length, (i) {
                      final selected = i == _periodIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: InkWell(
                          onTap: () => setState(() => _periodIndex = i),
                          child: Column(
                            children: [
                              Text(_periods[i],
                                  style: AppText.inter(size: 13.5, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.verdeDark : p.gray)),
                              const SizedBox(height: 6),
                              Container(width: 20, height: 2.5, color: selected ? AppColors.verde : Colors.transparent),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _kpiCard(p, 'CO₂', '${fmtNumber((summary?.totalCo2Kg ?? 0) / 1000, 1)}t', co2Delta)),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard(p, 'ÁRVORES', '${summary?.totalTrees ?? 0}', co2Delta)),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard(p, 'ECONOMIA', 'R\$ ${fmtNumber((summary?.totalEconomyBrl ?? 0) / 1000, 1)}k', economyDelta)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tendência e projeção', style: AppText.inter(size: 15, weight: FontWeight.w700, color: p.ink)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.verde.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                              child: Text('PROJ', style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.verde)),
                            ),
                          ],
                        ),
                        Text('CO₂ evitado por mês · tracejado = projetado', style: AppText.inter(size: 11.5, color: p.gray)),
                        const SizedBox(height: 18),
                        BioLineChart(
                          values: provider.trend.map((t) => t.co2Kg).toList(),
                          labels: provider.trend.map((t) => t.label).toList(),
                          color: AppColors.verde,
                          height: 110,
                          filled: true,
                          projectedFromIndex: provider.trend.indexWhere((t) => t.projected) == -1
                              ? null
                              : provider.trend.indexWhere((t) => t.projected),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Diesel vs Biometano', style: AppText.inter(size: 15, weight: FontWeight.w700, color: p.ink)),
                            Text(fossilCo2 > 0 ? '-${fmtNumber((1 - 0.4) * 100, 0)}%' : '-0%', style: AppText.inter(size: 13, weight: FontWeight.w700, color: AppColors.verdeDark)),
                          ],
                        ),
                        Text('de emissões', style: AppText.inter(size: 11.5, color: p.gray)),
                        const SizedBox(height: 18),
                        _fuelBar(p, 'Diesel B12', fossilCo2, maxCo2, const [Color(0xFFF59E0B), Color(0xFFDC2626)]),
                        const SizedBox(height: 16),
                        _fuelBar(p, 'Biometano', biometanoCo2, maxCo2, const [Color(0xFF34D399), AppColors.verdeDark]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViabilityScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.verde, AppColors.verdeDark]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: BioIcon('money', size: 18, color: Colors.white)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Viabilidade Econômica', style: AppText.inter(size: 14.5, weight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Diesel vs Biometano — quanto você economiza em R\$',
                                    style: AppText.inter(size: 11.5, color: Colors.white.withOpacity(0.85))),
                              ],
                            ),
                          ),
                          const BioIcon('chev-r', size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppColors.verde.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: BioIcon('file', size: 18, color: AppColors.verdeDark)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Relatórios ESG', style: AppText.inter(size: 14.5, weight: FontWeight.w700, color: p.ink)),
                                const SizedBox(height: 2),
                                Text('Gere PDFs prontos para stakeholders', style: AppText.inter(size: 11.5, color: p.gray)),
                              ],
                            ),
                          ),
                          BioIcon('chev-r', size: 14, color: p.gray2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _percentDelta(List<double> series) {
    if (series.length < 2) return 0;
    final prev = series[series.length - 2];
    final last = series.last;
    if (prev <= 0) return 0;
    return ((last - prev) / prev) * 100;
  }

  Widget _kpiCard(AppPalette p, String label, String value, double delta) {
    final positive = delta >= 0;
    final deltaColor = delta == 0 ? p.gray2 : (positive ? AppColors.verdeDark : AppColors.red);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(value, style: AppText.mono(size: 17, weight: FontWeight.w700, color: p.ink, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Row(
            children: [
              Transform.rotate(
                angle: positive ? -1.5708 : 1.5708,
                child: BioIcon('chev-r', size: 9, color: deltaColor, strokeWidth: 3),
              ),
              const SizedBox(width: 2),
              Text('${fmtNumber(delta.abs(), 0)}%', style: AppText.mono(size: 9.5, weight: FontWeight.w600, color: deltaColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelBar(AppPalette p, String label, double value, double max, List<Color> gradient) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.inter(size: 12.5, color: p.ink)),
            Text('${fmtNumber(value, 0)} kg', style: AppText.mono(size: 12, weight: FontWeight.w600, color: p.gray)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(999))),
              Container(
                height: 8,
                width: constraints.maxWidth * (ratio == 0 ? 0.02 : ratio),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
