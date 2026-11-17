import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _client;

  DashboardProvider(this._client);

  DashboardSummary? summary;
  List<TrendPoint> trend = [];
  List<FuelViability> fuelViability = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      final summaryJson = await _client.get('/dashboard/summary');
      summary = DashboardSummary.fromJson(summaryJson);
      final trendList = await _client.getList('/dashboard/trend');
      trend = trendList.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
      final viabilityList = await _client.getList('/dashboard/viability');
      fuelViability = viabilityList.map((e) => FuelViability.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Dashboard shows an empty/zeroed state either way.
    }
    loading = false;
    notifyListeners();
  }
}
