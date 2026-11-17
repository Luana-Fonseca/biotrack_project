import 'package:flutter_test/flutter_test.dart';

import 'package:biotrack/core/api_client.dart';
import 'package:biotrack/features/calculator/calculation_models.dart';
import 'package:biotrack/features/calculator/calculator_provider.dart';

void main() {
  test('defaults to Diesel B12, matching the design doc\'s original 2.31 kg/L baseline', () {
    final provider = CalculatorProvider(ApiClient());
    expect(provider.selectedFuelType, FuelType.dieselB12);
    expect(provider.selectedFuelType.co2PerLiter, 2.31);
  });

  test('previewCo2 recomputes per selected fuel type', () {
    final provider = CalculatorProvider(ApiClient());
    provider.setFuelLiters('100');
    provider.setFuelType(FuelType.dieselS10);
    expect(provider.previewCo2, 260.0);
    provider.setFuelType(FuelType.etanol);
    expect(provider.previewCo2, 151.0);
  });

  test('previewCo2 is zero when the liters field is empty or non-numeric', () {
    final provider = CalculatorProvider(ApiClient());
    expect(provider.previewCo2, 0);
    provider.setFuelLiters('abc');
    expect(provider.previewCo2, 0);
  });

  group('Cálculo de Distância da Descarbonização (route validator)', () {
    test('starts with empty origin/destination, requiring the user to type real addresses', () {
      final provider = CalculatorProvider(ApiClient());
      expect(provider.originAddress, isEmpty);
      expect(provider.destinationAddress, isEmpty);
      expect(provider.isAddressesValid, isFalse);
    });

    test('isAddressesValid is true once both addresses are filled and differ', () {
      final provider = CalculatorProvider(ApiClient());
      provider.setOriginAddress('Av Paulista 1000, Sao Paulo, SP');
      provider.setDestinationAddress('Rua Augusta 500, Sao Paulo, SP');
      expect(provider.isAddressesValid, isTrue);
    });

    test('isAddressesValid is false when origin and destination are the same address (case-insensitive)', () {
      final provider = CalculatorProvider(ApiClient());
      provider.setOriginAddress('Av Paulista 1000');
      provider.setDestinationAddress('AV PAULISTA 1000');
      expect(provider.isAddressesValid, isFalse);
    });

    test('isAddressesValid is false when either address is blank/whitespace-only', () {
      final provider = CalculatorProvider(ApiClient());
      provider.setOriginAddress('   ');
      provider.setDestinationAddress('Rua Augusta 500');
      expect(provider.isAddressesValid, isFalse);
    });

    test('calculate() rejects incomplete addresses client-side before hitting the network', () async {
      final provider = CalculatorProvider(ApiClient());
      provider.setFuelLiters('100');
      final ok = await provider.calculate();
      expect(ok, isFalse);
      expect(provider.lastError, isNotNull);
    });
  });
}
