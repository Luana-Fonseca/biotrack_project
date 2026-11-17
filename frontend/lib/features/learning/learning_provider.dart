import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'learning_models.dart';

class LearningProvider extends ChangeNotifier {
  final ApiClient _client;

  LearningProvider(this._client);

  List<TrilhaSummary> trilhas = [];
  Map<int, List<ModuleSummary>> modulesByTrilha = {};
  bool loading = false;

  Future<void> loadTrilhas() async {
    loading = true;
    notifyListeners();
    try {
      final list = await _client.getList('/learning/trilhas');
      trilhas = list.map((e) => TrilhaSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Keeps whatever was loaded before; screen shows empty state otherwise.
    }
    loading = false;
    notifyListeners();
  }

  Future<List<ModuleSummary>> loadModules(int trilhaId) async {
    final list = await _client.getList('/learning/trilhas/$trilhaId/modules');
    final modules = list.map((e) => ModuleSummary.fromJson(e as Map<String, dynamic>)).toList();
    modulesByTrilha[trilhaId] = modules;
    notifyListeners();
    return modules;
  }

  Future<void> completeModule(int moduleId, int trilhaId) async {
    await _client.post('/learning/modules/$moduleId/complete');
    await loadModules(trilhaId);
    await loadTrilhas();
  }
}
