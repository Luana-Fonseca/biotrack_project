import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_base_url.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Base URL for the BioTrack backend.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
/// Without that override: on web, derived at runtime from the page's own
/// host (see api_base_url_web.dart) so it survives the LAN IP changing;
/// everywhere else, the Android emulator's host-loopback alias.
const String _buildTimeBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

String _resolveDefaultBaseUrl() {
  if (_buildTimeBaseUrl.isNotEmpty) return _buildTimeBaseUrl;
  return webHostBaseUrl() ?? 'http://10.0.2.2:8080';
}

/// Thin wrapper around Dio that attaches the JWT, and translates error
/// responses into [ApiException] using the backend's ErrorResponse shape.
class ApiClient {
  final Dio _dio;
  final TokenStorage tokenStorage;

  ApiClient({TokenStorage? tokenStorage, String? baseUrl})
      : tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? _resolveDefaultBaseUrl(),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await this.tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(await _run(() => _dio.get(path, queryParameters: query)));
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await _run(() => _dio.get(path, queryParameters: query));
    if (res.data is List) return res.data as List<dynamic>;
    return _unwrapPageContent(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    return _unwrap(await _run(() => _dio.post(path, data: body)));
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    return _unwrap(await _run(() => _dio.put(path, data: body)));
  }

  Future<void> delete(String path) async {
    await _run(() => _dio.delete(path));
  }

  Future<Uint8List> getBytes(String path) async {
    final res = await _run(() => _dio.get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        ));
    return Uint8List.fromList(res.data as List<int>);
  }

  Future<Response> _run(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Map<String, dynamic> _unwrap(Response res) {
    if (res.data is Map<String, dynamic>) return res.data as Map<String, dynamic>;
    return <String, dynamic>{};
  }

  List<dynamic> _unwrapPageContent(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return const [];
  }

  ApiException _toApiException(DioException e) {
    final res = e.response;
    if (res != null && res.data is Map<String, dynamic>) {
      final body = res.data as Map<String, dynamic>;
      final fieldsRaw = body['fields'];
      Map<String, String>? fields;
      if (fieldsRaw is Map) {
        fields = fieldsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return ApiException(
        res.statusCode ?? 0,
        (body['message'] as String?) ?? 'Erro inesperado',
        fields: fields,
      );
    }
    return ApiException(res?.statusCode ?? 0, e.message ?? 'Falha de conexão com o servidor');
  }
}
