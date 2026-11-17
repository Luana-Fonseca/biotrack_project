enum ReportType { ambiental, social, governanca }

enum ReportPeriod { diario, semanal, mensal, personalizado }

extension ReportTypeX on ReportType {
  String get apiValue => switch (this) {
        ReportType.ambiental => 'AMBIENTAL',
        ReportType.social => 'SOCIAL',
        ReportType.governanca => 'GOVERNANCA',
      };

  String get label => switch (this) {
        ReportType.ambiental => 'Ambiental',
        ReportType.social => 'Social',
        ReportType.governanca => 'Governança',
      };

  /// Abbreviated form used where horizontal space is tight (the 3-column type picker).
  String get shortLabel => switch (this) {
        ReportType.ambiental => 'Ambiental',
        ReportType.social => 'Social',
        ReportType.governanca => 'Govern.',
      };

  String get icon => switch (this) {
        ReportType.ambiental => 'leaf',
        ReportType.social => 'user',
        ReportType.governanca => 'shield',
      };
}

extension ReportPeriodX on ReportPeriod {
  String get apiValue => switch (this) {
        ReportPeriod.diario => 'DIARIO',
        ReportPeriod.semanal => 'SEMANAL',
        ReportPeriod.mensal => 'MENSAL',
        ReportPeriod.personalizado => 'PERSONALIZADO',
      };

  String get label => switch (this) {
        ReportPeriod.diario => 'Diário',
        ReportPeriod.semanal => 'Semanal',
        ReportPeriod.mensal => 'Mensal',
        ReportPeriod.personalizado => 'Personalizado',
      };
}

class ReportSummary {
  final int id;
  final String name;
  final ReportType type;
  final ReportPeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int sizeBytes;
  final DateTime createdAt;

  ReportSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.sizeBytes,
    required this.createdAt,
  });

  String get typeLabel => type.label;

  String get periodLabel => '${_fmt(periodStart)} - ${_fmt(periodEnd)}';

  String get sizeLabel {
    final kb = sizeBytes / 1024;
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${kb.toStringAsFixed(0)} KB';
  }

  static String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        type: ReportType.values.firstWhere((t) => t.apiValue == json['type'], orElse: () => ReportType.ambiental),
        period: ReportPeriod.values.firstWhere((p) => p.apiValue == json['period'], orElse: () => ReportPeriod.mensal),
        periodStart: DateTime.tryParse(json['periodStart'] as String? ?? '') ?? DateTime.now(),
        periodEnd: DateTime.tryParse(json['periodEnd'] as String? ?? '') ?? DateTime.now(),
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
