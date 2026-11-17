class DashboardSummary {
  final int totalCalculations;
  final double totalCo2Kg;
  final double totalEconomyBrl;
  final int totalTrees;
  final int xp;
  final int streakDays;
  final int rank;
  final int totalUsers;

  DashboardSummary({
    required this.totalCalculations,
    required this.totalCo2Kg,
    required this.totalEconomyBrl,
    required this.totalTrees,
    required this.xp,
    required this.streakDays,
    required this.rank,
    required this.totalUsers,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        totalCalculations: json['totalCalculations'] as int? ?? 0,
        totalCo2Kg: (json['totalCo2Kg'] as num?)?.toDouble() ?? 0,
        totalEconomyBrl: (json['totalEconomyBrl'] as num?)?.toDouble() ?? 0,
        totalTrees: json['totalTrees'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        streakDays: json['streakDays'] as int? ?? 0,
        rank: json['rank'] as int? ?? 0,
        totalUsers: json['totalUsers'] as int? ?? 0,
      );
}

class FuelViability {
  final String fuelType;
  final String fuelLabel;
  final int calculations;
  final double liters;
  final double co2AvoidedKg;
  final double economyBrl;

  FuelViability({
    required this.fuelType,
    required this.fuelLabel,
    required this.calculations,
    required this.liters,
    required this.co2AvoidedKg,
    required this.economyBrl,
  });

  factory FuelViability.fromJson(Map<String, dynamic> json) => FuelViability(
        fuelType: json['fuelType'] as String? ?? '',
        fuelLabel: json['fuelLabel'] as String? ?? '',
        calculations: json['calculations'] as int? ?? 0,
        liters: (json['liters'] as num?)?.toDouble() ?? 0,
        co2AvoidedKg: (json['co2AvoidedKg'] as num?)?.toDouble() ?? 0,
        economyBrl: (json['economyBrl'] as num?)?.toDouble() ?? 0,
      );
}

class TrendPoint {
  final String label;
  final double co2Kg;
  final double economyBrl;
  final bool projected;

  TrendPoint({required this.label, required this.co2Kg, required this.economyBrl, required this.projected});

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        label: json['label'] as String? ?? '',
        co2Kg: (json['co2Kg'] as num?)?.toDouble() ?? 0,
        economyBrl: (json['economyBrl'] as num?)?.toDouble() ?? 0,
        projected: json['projected'] as bool? ?? false,
      );
}
