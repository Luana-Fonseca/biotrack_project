import 'dart:html' as html;

/// On web, default to the same host that served this page, on port 8080 —
/// the backend conventionally runs alongside the static file server on the
/// same machine (`mvn spring-boot:run` + `npx serve` on one PC, reached from
/// a phone over LAN). Deriving it at runtime means a web build baked with
/// one LAN IP keeps working after the router hands the PC a different one —
/// no rebuild needed — as long as nothing overrode API_BASE_URL at build time.
String? webHostBaseUrl() {
  final host = html.window.location.hostname;
  if (host == null || host.isEmpty) return null;
  return 'http://$host:8080';
}
