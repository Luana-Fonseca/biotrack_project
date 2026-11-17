class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, String>? fields;

  ApiException(this.statusCode, this.message, {this.fields});

  @override
  String toString() => message;
}
