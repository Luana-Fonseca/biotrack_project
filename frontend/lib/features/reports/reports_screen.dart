import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../calculator/calculator_provider.dart';
import 'reports_models.dart';
import 'reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Only the Ambiental report is offered for now — Social/Governança were removed from the picker.
  static const ReportType _type = ReportType.ambiental;
  DateTime _periodStart =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime.now();

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadReports();
      context.read<CalculatorProvider>().loadHistory();
    });
  }

  String get _periodLabel {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    final sameMonth = _periodStart.year == _periodEnd.year &&
        _periodStart.month == _periodEnd.month;
    final title = sameMonth
        ? '${_monthNames[_periodStart.month - 1]} ${_periodStart.year}'
        : '${fmt(_periodStart)} - ${fmt(_periodEnd)}';
    return title;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _periodStart, end: _periodEnd),
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked.start;
        _periodEnd = picked.end;
      });
    }
  }

  Future<void> _generate(ReportsProvider provider) async {
    final ok = await provider.generate(
      type: _type,
      period: ReportPeriod.personalizado,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
    );
    if (!mounted) return;
    if (!ok) {
      if (provider.lastError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(provider.lastError!)));
      }
      return;
    }
    // Generating only creates the report server-side — download it immediately too, so
    // clicking "Gerar PDF agora" actually produces the file instead of just listing it below.
    final report = provider.reports.first;
    final downloaded = await provider.download(report);
    if (!mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Relatório gerado e baixado: ${provider.lastSavedPath}')));
    } else if (provider.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.lastError!)));
    }
  }

  Future<void> _download(ReportsProvider provider, ReportSummary report) async {
    final ok = await provider.download(report);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Relatório salvo: ${provider.lastSavedPath}')));
    } else if (provider.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.lastError!)));
    }
  }

  /// A rough client-side estimate (pages + size) shown before generating —
  /// the real PDF is built server-side by ReportService, so this won't match
  /// exactly, but it's computed from the same period's real calculation
  /// count rather than a made-up number.
  (int pages, int bytes) _estimate(int calcsInPeriod) {
    if (calcsInPeriod == 0) return (1, 6000);
    int pages = 1 + 2 + (calcsInPeriod / 15).ceil();
    int bytes = 8000 + 45000 + calcsInPeriod * 120;
    return (pages, bytes);
  }

  String _formatBytes(int bytes) {
    final kb = bytes / 1024;
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final calcProvider = context.watch<CalculatorProvider>();
    final p = context.palette;

    final calcsInPeriod = calcProvider.history.where((c) {
      final d = c.createdAt;
      return !d.isBefore(_periodStart) &&
          !d.isAfter(_periodEnd.add(const Duration(days: 1)));
    }).length;
    final (estPages, estBytes) = _estimate(calcsInPeriod);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
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
            Text('Relatórios ESG',
                style: AppText.inter(
                    size: 24,
                    weight: FontWeight.w700,
                    color: AppColors.azul,
                    letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Gere PDFs prontos para stakeholders.',
                style: AppText.inter(size: 13, color: p.gray)),
            const SizedBox(height: 22),
            Text('TIPO DE RELATÓRIO',
                style: AppText.mono(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: p.gray,
                    letterSpacing: 0.4)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                  color: AppColors.azul,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  BioIcon(_type.icon,
                      size: 20, color: Colors.white, strokeWidth: 2),
                  const SizedBox(width: 10),
                  Text(_type.label,
                      style: AppText.inter(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('PERÍODO',
                style: AppText.mono(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: p.gray,
                    letterSpacing: 0.4)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickRange,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_periodLabel,
                            style: AppText.inter(
                                size: 14.5,
                                weight: FontWeight.w600,
                                color: p.ink)),
                        const SizedBox(height: 2),
                        Text(
                          '${_periodStart.day.toString().padLeft(2, '0')}/${_periodStart.month.toString().padLeft(2, '0')} → ${_periodEnd.day.toString().padLeft(2, '0')}/${_periodEnd.month.toString().padLeft(2, '0')}',
                          style: AppText.inter(size: 11.5, color: p.gray),
                        ),
                      ],
                    ),
                    BioIcon('chev-d', size: 16, color: p.gray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.verde.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const BioIcon('file', size: 20, color: AppColors.verdeDark),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview',
                          style: AppText.inter(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: AppColors.verdeDark)),
                      const SizedBox(height: 2),
                      Text(
                          '$estPages páginas · ${_formatBytes(estBytes)} estimado',
                          style: AppText.inter(
                              size: 11.5, color: p.ink.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    provider.generating ? null : () => _generate(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  disabledBackgroundColor: p.gray3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: provider.generating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const BioIcon('download',
                              size: 16, color: Colors.white, strokeWidth: 2.5),
                          const SizedBox(width: 8),
                          Text('Gerar PDF agora',
                              style: AppText.inter(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Text('ANTERIORES',
                style: AppText.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    color: p.gray,
                    letterSpacing: 0.4)),
            const SizedBox(height: 12),
            if (provider.loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (provider.reports.isEmpty)
              Text('Nenhum relatório gerado ainda.',
                  style: AppText.inter(size: 13, color: p.gray))
            else
              ...provider.reports.map((r) => InkWell(
                    onTap: () => _download(provider, r),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: _typeColor(r.type).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                                child: BioIcon('file',
                                    size: 17, color: _typeColor(r.type))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: AppText.inter(
                                        size: 13.5,
                                        weight: FontWeight.w600,
                                        color: p.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                    '${r.typeLabel} · ${r.sizeLabel} · ${r.periodLabel}',
                                    style:
                                        AppText.mono(size: 10.5, color: p.gray),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          BioIcon('download',
                              size: 17, color: AppColors.verdeDark),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Color _typeColor(ReportType type) => switch (type) {
        ReportType.ambiental => AppColors.verdeDark,
        ReportType.social => AppColors.azul,
        ReportType.governanca => const Color(0xFF9333EA),
      };
}
