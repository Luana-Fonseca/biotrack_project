import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'calculation_models.dart';
import 'calculator_repository.dart';

class CalculatorProvider extends ChangeNotifier {
  final CalculatorRepository _repository;

  CalculatorProvider(ApiClient client) : _repository = CalculatorRepository(client);

  FuelType selectedFuelType = FuelType.dieselB12;
  VehicleType selectedVehicleType = VehicleType.carro;
  String fuelLitersText = '';
  String originAddress = '';
  String destinationAddress = '';

  bool isBusy = false;
  String? lastError;
  CalculationResult? lastResult;
  List<CalculationResult> history = [];
  bool loadingHistory = false;

  double get previewCo2 {
    final liters = double.tryParse(fuelLitersText.replaceAll(',', '.'));
    if (liters == null || liters <= 0) return 0;
    return liters * selectedFuelType.co2PerLiter;
  }

  void setFuelType(FuelType type) {
    selectedFuelType = type;
    notifyListeners();
  }

  void setVehicleType(VehicleType type) {
    selectedVehicleType = type;
    notifyListeners();
  }

  void setFuelLiters(String value) {
    fuelLitersText = value;
    notifyListeners();
  }

  void setOriginAddress(String value) {
    originAddress = value;
    notifyListeners();
  }

  void setDestinationAddress(String value) {
    destinationAddress = value;
    notifyListeners();
  }

  /// "Cálculo de Distância da Descarbonização" needs two different, non-blank
  /// addresses before it's worth sending to the backend's geocoding/routing
  /// pipeline — this is checked client-side so a trivially-wrong input never
  /// even reaches the network.
  bool get isAddressesValid {
    final origin = originAddress.trim();
    final destination = destinationAddress.trim();
    if (origin.isEmpty || destination.isEmpty) return false;
    return origin.toLowerCase() != destination.toLowerCase();
  }

  Future<bool> calculate() async {
    if (!isAddressesValid) {
      lastError = 'Informe dois endereços diferentes para calcular a rota.';
      notifyListeners();
      return false;
    }
    final liters = double.tryParse(fuelLitersText.replaceAll(',', '.'));
    if (liters == null || liters <= 0) {
      lastError = 'Informe uma quantidade de litros válida.';
      notifyListeners();
      return false;
    }

    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      lastResult = await _repository.calculate(
        fuelType: selectedFuelType,
        vehicleType: selectedVehicleType,
        fuelLiters: liters,
        originAddress: originAddress.trim(),
        destinationAddress: destinationAddress.trim(),
      );
      isBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      isBusy = false;
      lastError = e is ApiException ? e.message : 'Não foi possível calcular. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadHistory() async {
    loadingHistory = true;
    notifyListeners();
    try {
      history = await _repository.history();
    } catch (_) {
      // Keep whatever was loaded before; the history screen shows an empty state either way.
    }
    loadingHistory = false;
    notifyListeners();
  }
}
