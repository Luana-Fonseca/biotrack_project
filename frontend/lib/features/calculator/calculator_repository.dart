import '../../core/api_client.dart';
import 'calculation_models.dart';

class CalculatorRepository {
  final ApiClient _client;

  CalculatorRepository(this._client);

  Future<CalculationResult> calculate({
    required FuelType fuelType,
    required VehicleType vehicleType,
    required double fuelLiters,
    required String originAddress,
    required String destinationAddress,
  }) async {
    final json = await _client.post('/calculator/calculate', body: {
      'fuelType': fuelType.apiValue,
      'vehicleType': vehicleType.apiValue,
      'fuelLiters': fuelLiters,
      'originAddress': originAddress,
      'destinationAddress': destinationAddress,
    });
    return CalculationResult.fromJson(json);
  }

  Future<List<CalculationResult>> history() async {
    final list = await _client.getList('/calculator/history');
    return list.map((e) => CalculationResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
