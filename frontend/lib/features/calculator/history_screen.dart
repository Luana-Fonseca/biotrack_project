import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/floating_sheet.dart';
import 'calculation_models.dart';
import 'calculator_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryFilter { todos, esteMes, ultimos3m, esteAno }

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CalculatorProvider>().loadHistory());
  }

  List<CalculationResult> _applyFilter(List<CalculationResult> all) {
    final now = DateTime.now();
    switch (_filter) {
      case _HistoryFilter.todos:
        return all;
      case _HistoryFilter.esteMes:
        return all
            .where((r) =>
                r.createdAt.year == now.year && r.createdAt.month == now.month)
            .toList();
      case _HistoryFilter.ultimos3m:
        final cutoff = DateTime(now.year, now.month - 2, 1);
        return all.where((r) => r.createdAt.isAfter(cutoff)).toList();
      case _HistoryFilter.esteAno:
        return all.where((r) => r.createdAt.year == now.year).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final p = context.palette;
    final filtered = _applyFilter(provider.history);

    final totalCo2Ton =
        provider.history.fold<double>(0, (sum, r) => sum + r.co2Kg) / 1000;
    final totalTrees =
        provider.history.fold<int>(0, (sum, r) => sum + r.treesEquivalent);
    final totalEconomy =
        provider.history.fold<double>(0, (sum, r) => sum + r.economyBrl);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: provider.loadingHistory
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
                  const SizedBox(height: 8),
                  Text('Histórico',
                      style: AppText.inter(
                          size: 26,
                          weight: FontWeight.w700,
                          color: AppColors.azul,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                        Text(
                            'IMPACTO ACUMULADO · ${provider.history.length} CÁLCULOS',
                            style: AppText.mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: AppColors.verde,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                                child: _statColumn(fmtNumber(totalCo2Ton, 2),
                                    'ton', 'CO₂ evitado')),
                            Expanded(
                                child: _statColumn(fmtNumber(totalTrees, 0),
                                    'salvas', 'Árvores')),
                            Expanded(
                                child: _statColumn(
                                    '${fmtNumber(totalEconomy / 1000, 1)}k',
                                    'R\$',
                                    'Economia')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _filterChip(p, 'Todos', _HistoryFilter.todos),
                      const SizedBox(width: 8),
                      _filterChip(p, 'Este mês', _HistoryFilter.esteMes),
                      const SizedBox(width: 8),
                      _filterChip(p, 'Últimos 3m', _HistoryFilter.ultimos3m),
                      const SizedBox(width: 8),
                      _filterChip(p, 'Este ano', _HistoryFilter.esteAno),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text('Nenhum cálculo neste período.',
                          style: AppText.inter(size: 13, color: p.gray)),
                    )
                  else
                    ...filtered.map((r) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showDetail(context, p, r),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: r.anomaly
                                      ? const Color(0xFFF59E0B)
                                      : AppColors.verde,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: BioIcon(r.anomaly ? 'alert' : (r.vehicleType?.icon ?? 'flame'),
                                      size: 19,
                                      color: Colors.white,
                                      strokeWidth: 2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${fmtNumber(r.fuelLiters, 0)} L · ${fmtNumber(r.distanceKm, 1)} km',
                                        style: AppText.inter(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: AppColors.azul)),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.anomaly
                                          ? 'Fora do padrão · ${_fmtDate(r.createdAt)}'
                                          : _fmtDate(r.createdAt),
                                      style: AppText.inter(
                                          size: 11.5,
                                          color: r.anomaly
                                              ? const Color(0xFFB45309)
                                              : p.gray2),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(fmtNumber(r.co2Kg, 0),
                                      style: AppText.mono(
                                          size: 15,
                                          weight: FontWeight.w700,
                                          color: AppColors.verdeDark)),
                                  Text('kg CO₂',
                                      style: AppText.inter(
                                          size: 10.5, color: p.gray2)),
                                ],
                              ),
                            ],
                          ),
                        ))),
                ],
              ),
      ),
    );
  }

  Widget _statColumn(String value, String unit, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppText.mono(
                size: 20,
                weight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3)),
        Text(unit,
            style: AppText.inter(
                size: 10.5, color: Colors.white.withOpacity(0.75))),
        const SizedBox(height: 2),
        Text(label,
            style: AppText.inter(
                size: 10.5, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }

  Widget _filterChip(AppPalette p, String label, _HistoryFilter value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.azul : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.azul : p.border),
        ),
        child: Text(label,
            style: AppText.inter(
                size: 11.5,
                weight: FontWeight.w600,
                color: selected ? Colors.white : p.ink)),
      ),
    );
  }

  void _showDetail(BuildContext context, AppPalette p, CalculationResult r) {
    showFloatingSheet(
      context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detalhes do cálculo',
                      style: AppText.inter(size: 18, weight: FontWeight.w700, color: AppColors.azul)),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: BioIcon('close', size: 18, color: p.gray),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_fmtDate(r.createdAt), style: AppText.inter(size: 12, color: p.gray2)),
              const SizedBox(height: 20),
              _detailRow(p, icon: 'gas', label: 'Combustível', value: r.fuelTypeLabel),
              if (r.vehicleType != null)
                _detailRow(p, icon: r.vehicleType!.icon, label: 'Veículo', value: r.vehicleTypeLabel ?? r.vehicleType!.label),
              _detailRow(p, icon: 'drop', label: 'Litros', value: '${fmtNumber(r.fuelLiters, 1)} L'),
              _detailRow(p, icon: 'route', label: 'Endereço de origem', value: r.originAddress),
              _detailRow(p, icon: 'route', label: 'Endereço de destino', value: r.destinationAddress),
              _detailRow(
                p,
                icon: 'chart',
                label: 'Distância',
                value: '${fmtNumber(r.distanceKm, r.distanceKm < 100 ? 1 : 0)} km'
                    '${r.distanceEstimated ? ' (estimada)' : ''}',
              ),
              _detailRow(p, icon: 'leaf', label: 'CO₂ evitado', value: '${fmtNumber(r.co2Kg, 0)} kg'),
              _detailRow(p, icon: 'money', label: 'Economia estimada', value: fmtBRL(r.economyBrl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(AppPalette p, {required String icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.azul.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: BioIcon(icon, size: 15, color: AppColors.azul)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.inter(size: 11, color: p.gray)),
                const SizedBox(height: 2),
                Text(value, style: AppText.inter(size: 14, weight: FontWeight.w600, color: p.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez'
    ];
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} · ${local.year}';
  }
}
