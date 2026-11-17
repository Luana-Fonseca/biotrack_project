import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/file_saver.dart';
import 'reports_models.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiClient _client;

  ReportsProvider(this._client);

  List<ReportSummary> reports = [];
  bool loading = false;
  bool generating = false;
  String? lastError;
  String? lastSavedPath;

  Future<void> loadReports() async {
    loading = true;
    notifyListeners();
    try {
      final list = await _client.getList('/reports/list');
      reports = list.map((e) => ReportSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Keeps whatever was loaded before; screen shows empty state otherwise.
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> generate({
    required ReportType type,
    required ReportPeriod period,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    generating = true;
    lastError = null;
    notifyListeners();
    try {
      final json = await _client.post('/reports/generate', body: {
        'type': type.apiValue,
        'period': period.apiValue,
        'periodStart': periodStart.toIso8601String().split('T').first,
        'periodEnd': periodEnd.toIso8601String().split('T').first,
      });
      final report = ReportSummary.fromJson(json);
      reports = [report, ...reports];
      generating = false;
      notifyListeners();
      return true;
    } catch (e) {
      generating = false;
      lastError = e is ApiException ? e.message : 'Não foi possível gerar o relatório.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> download(ReportSummary report) async {
    try {
      final bytes = await _client.getBytes('/reports/${report.id}/download');
      final fileName = '${report.name.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_')}.pdf';
      lastSavedPath = await saveBytesAndGetLocation(bytes, fileName);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e is ApiException ? e.message : 'Não foi possível baixar o relatório.';
      notifyListeners();
      return false;
    }
  }
}
