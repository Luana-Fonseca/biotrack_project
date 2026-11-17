import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final ApiClient _client;

  AuthProvider(ApiClient client) : _repository = AuthRepository(client), _client = client;

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  bool isBusy = false;
  String? lastError;

  Future<void> bootstrap() async {
    final token = await _client.tokenStorage.read();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _repository.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await _client.tokenStorage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? profession,
    String? education,
  }) async {
    return _runAuth(() => _repository.register(name: name, email: email, password: password, profession: profession, education: education));
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuth(() => _repository.login(email: email, password: password));
  }

  Future<bool> _runAuth(Future<AuthResult> Function() call) async {
    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await call();
      await _client.tokenStorage.write(result.accessToken);
      currentUser = result.user;
      status = AuthStatus.authenticated;
      isBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      isBusy = false;
      lastError = e is ApiException ? e.message : 'Não foi possível concluir. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _client.tokenStorage.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updatePhoto(String base64) async {
    try {
      currentUser = await _repository.updatePhoto(base64);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile({required String name, String? profession, String? city, DateTime? birthDate}) async {
    try {
      currentUser = await _repository.updateProfile(name: name, profession: profession, city: city, birthDate: birthDate);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e is ApiException ? e.message : 'Não foi possível salvar o perfil.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String newPassword}) async {
    try {
      currentUser = await _repository.changePassword(newPassword: newPassword);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e is ApiException ? e.message : 'Não foi possível trocar a senha.';
      notifyListeners();
      return false;
    }
  }
}
