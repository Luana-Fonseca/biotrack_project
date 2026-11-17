enum FuelType {
  dieselS10('DIESEL_S10', 'Diesel S10', 2.60),
  dieselB12('DIESEL_B12', 'Diesel B12', 2.31),
  gasolina('GASOLINA', 'Gasolina', 2.21),
  etanol('ETANOL', 'Etanol', 1.51);

  final String apiValue;
  final String label;
  final double co2PerLiter;

  const FuelType(this.apiValue, this.label, this.co2PerLiter);
}

/// Categorizes which vehicle the fuel was burned in — carro/caminhão/ônibus. This never changes
/// the CO2/economy math (that depends only on [FuelType]); it just lets calculations be
/// grouped/reported by vehicle instead of only by fuel.
enum VehicleType {
  carro('CARRO', 'Carro', 'car'),
  caminhao('CAMINHAO', 'Caminhão', 'truck'),
  onibus('ONIBUS', 'Ônibus', 'bus');

  final String apiValue;
  final String label;
  final String icon;

  const VehicleType(this.apiValue, this.label, this.icon);
}

class CalculationResult {
  final int id;
  final FuelType fuelType;
  final String fuelTypeLabel;
  final VehicleType? vehicleType;
  final String? vehicleTypeLabel;
  final double fuelLiters;
  final String originAddress;
  final String destinationAddress;
  final double distanceKm;
  final bool distanceEstimated;
  final double co2Kg;
  final int treesEquivalent;
  final double economyBrl;
  final bool anomaly;
  final String? anomalyReason;
  final DateTime createdAt;

  CalculationResult({
    required this.id,
    required this.fuelType,
    required this.fuelTypeLabel,
    this.vehicleType,
    this.vehicleTypeLabel,
    required this.fuelLiters,
    required this.originAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.distanceEstimated,
    required this.co2Kg,
    required this.treesEquivalent,
    required this.economyBrl,
    required this.anomaly,
    required this.anomalyReason,
    required this.createdAt,
  });

  factory CalculationResult.fromJson(Map<String, dynamic> json) => CalculationResult(
        id: json['id'] as int,
        fuelType: FuelType.values.firstWhere((f) => f.apiValue == json['fuelType'], orElse: () => FuelType.dieselB12),
        fuelTypeLabel: json['fuelTypeLabel'] as String? ?? '',
        vehicleType: _vehicleTypeFromJson(json['vehicleType'] as String?),
        vehicleTypeLabel: json['vehicleTypeLabel'] as String?,
        fuelLiters: (json['fuelLiters'] as num).toDouble(),
        originAddress: json['originAddress'] as String? ?? '',
        destinationAddress: json['destinationAddress'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        distanceEstimated: json['distanceEstimated'] as bool? ?? false,
        co2Kg: (json['co2Kg'] as num).toDouble(),
        treesEquivalent: json['treesEquivalent'] as int? ?? 0,
        economyBrl: (json['economyBrl'] as num).toDouble(),
        anomaly: json['anomaly'] as bool? ?? false,
        anomalyReason: json['anomalyReason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

VehicleType? _vehicleTypeFromJson(String? apiValue) {
  if (apiValue == null) return null;
  for (final v in VehicleType.values) {
    if (v.apiValue == apiValue) return v;
  }
  return null;
}
