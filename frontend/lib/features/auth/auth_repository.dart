import '../../core/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? profession,
    String? education,
  }) async {
    final json = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'profession': profession,
      'education': education,
    });
    return AuthResult.fromJson(json);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _client.post('/auth/login', body: {'email': email, 'password': password});
    return AuthResult.fromJson(json);
  }

  Future<UserModel> me() async {
    final json = await _client.get('/users/me');
    return UserModel.fromJson(json);
  }

  Future<UserModel> updatePhoto(String photoBase64) async {
    final json = await _client.put('/users/me/photo', body: {'photoBase64': photoBase64});
    return UserModel.fromJson(json);
  }

  Future<UserModel> updateProfile({required String name, String? profession, String? city, DateTime? birthDate}) async {
    final json = await _client.put('/users/me/profile', body: {
      'name': name,
      'profession': profession,
      'city': city,
      'birthDate': birthDate?.toIso8601String().split('T').first,
    });
    return UserModel.fromJson(json);
  }

  Future<UserModel> changePassword({required String newPassword}) async {
    final json = await _client.put('/users/me/password', body: {
      'newPassword': newPassword,
    });
    return UserModel.fromJson(json);
  }
}
