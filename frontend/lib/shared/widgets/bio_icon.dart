import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a small, curated icon set as inline SVG built at runtime, so
/// swapping/adding icons doesn't require bundling asset files.
class BioIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final double strokeWidth;

  const BioIcon(this.name, {super.key, this.size = 20, this.color = Colors.black, this.strokeWidth = 1.8});

  static final Map<String, List<String>> _paths = {
    'leaf': (s) => ['<path $s d="M5 21c0-9 6-16 15-16-1 9-6 15-15 16z"/><path $s d="M5 21c3-4 6-7 10-10"/>'],
    'calc': (s) => ['<rect $s x="5" y="3" width="14" height="18" rx="2"/><path $s d="M8 8h8M8 12h.01M12 12h.01M16 12h.01M8 16h.01M12 16h.01M16 16h.01"/>'],
    'chart': (s) => ['<path $s d="M4 20V10M11 20V4M18 20v-7"/>'],
    'book': (s) => ['<path $s d="M4 5a2 2 0 012-2h6v18H6a2 2 0 00-2 2V5z"/><path $s d="M20 5a2 2 0 00-2-2h-6v18h6a2 2 0 012 2V5z"/>'],
    'user': (s) => ['<circle $s cx="12" cy="8" r="4"/><path $s d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8"/>'],
    'plus': (s) => ['<path $s d="M12 5v14M5 12h14"/>'],
    'close': (s) => ['<path $s d="M6 6l12 12M18 6L6 18"/>'],
    'chev-r': (s) => ['<path $s d="M9 6l6 6-6 6"/>'],
    'chev-l': (s) => ['<path $s d="M15 6l-6 6 6 6"/>'],
    'chev-d': (s) => ['<path $s d="M6 9l6 6 6-6"/>'],
    'check': (s) => ['<path $s d="M4 12l5 5L20 6"/>'],
    'gas': (s) => ['<path $s d="M6 3h9v18H6z"/><path $s d="M15 8h2l2 2v7a1.5 1.5 0 01-3 0v-3h-1"/>'],
    'drop': (s) => ['<path $s d="M12 3s7 7.5 7 12a7 7 0 01-14 0c0-4.5 7-12 7-12z"/>'],
    'twin': (s) => ['<rect $s x="3" y="4" width="8" height="8" rx="1"/><rect $s x="13" y="12" width="8" height="8" rx="1"/><path $s d="M11 8h2M13 8V6M11 16H9M11 16v2"/>'],
    'block': (s) => ['<path $s d="M12 3l8 4v10l-8 4-8-4V7z"/><path $s d="M4 7l8 4 8-4M12 11v10"/>'],
    'truck': (s) => ['<path $s d="M2 7h11v9H2zM13 10h4l3 3v3h-7z"/><circle $s cx="6" cy="18" r="1.6"/><circle $s cx="17" cy="18" r="1.6"/>'],
    'car': (s) => ['<path $s d="M4 16V11l2-5h12l2 5v5"/><path $s d="M2 16h20"/><circle $s cx="7" cy="16.5" r="1.6"/><circle $s cx="17" cy="16.5" r="1.6"/>'],
    'bus': (s) => ['<rect $s x="3" y="4" width="18" height="13" rx="2"/><path $s d="M3 11h18M8 4v7M16 4v7"/><circle $s cx="7" cy="19" r="1.6"/><circle $s cx="17" cy="19" r="1.6"/>'],
    'esg': (s) => ['<circle $s cx="12" cy="12" r="9"/><path $s d="M8 12h8M12 8v8"/>'],
    'tree': (s) => ['<path $s d="M12 3l5 7h-3l4 6h-4v5h-4v-5H6l4-6H7z"/>'],
    'money': (s) => ['<circle $s cx="12" cy="12" r="9"/><path $s d="M12 7v10M9.5 9.5c0-1.4 1.1-2 2.5-2s2.5.9 2.5 2-1 1.5-2.5 2-2.5.7-2.5 2 1.1 2 2.5 2 2.5-.6 2.5-2"/>'],
    'route': (s) => ['<circle $s cx="6" cy="6" r="2.2"/><circle $s cx="18" cy="18" r="2.2"/><path $s d="M6 8v4a4 4 0 004 4h4"/>'],
    'file': (s) => ['<path $s d="M6 2h9l5 5v15H6z"/><path $s d="M15 2v5h5"/>'],
    'bell': (s) => ['<path $s d="M6 10a6 6 0 1112 0c0 5 2 6 2 6H4s2-1 2-6z"/><path $s d="M10 20a2 2 0 004 0"/>'],
    'globe': (s) => ['<circle $s cx="12" cy="12" r="9"/><path $s d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/>'],
    'shield': (s) => ['<path $s d="M12 2l8 3v6c0 5-4 9-8 11-4-2-8-6-8-11V5z"/>'],
    'logout': (s) => ['<path $s d="M9 4H5a1 1 0 00-1 1v14a1 1 0 001 1h4M16 17l5-5-5-5M21 12H9"/>'],
    'download': (s) => ['<path $s d="M12 3v13m-5-5l5 5 5-5M4 21h16"/>'],
    'flame': (s) => ['<path $s d="M12 2s5 4 5 10a5 5 0 01-10 0c0-2 1-3 1-3s-1 5 2 5 3-4 2-6c0-2 0-4 0-6z"/>'],
    'award': (s) => ['<circle $s cx="12" cy="8" r="5"/><path $s d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5"/>'],
    'trophy': (s) => ['<path $s d="M6 4h12v6a6 6 0 01-12 0zM4 4h2v4a2 2 0 01-2-2zM18 4h2v2a2 2 0 01-2 2M9 20h6M10 20v-4h4v4"/>'],
    'edit': (s) => ['<path $s d="M12 20h9M16.5 3.5a2.1 2.1 0 013 3L7 19l-4 1 1-4 12.5-12.5z"/>'],
    'camera': (s) => ['<path $s d="M4 8h3l2-2h6l2 2h3v11H4z"/><circle $s cx="12" cy="13" r="3.5"/>'],
    'image': (s) => ['<rect $s x="3" y="4" width="18" height="16" rx="2"/><circle $s cx="9" cy="10" r="1.6"/><path $s d="M21 16l-6-5-4 4-2-2-6 5"/>'],
    'moon': (s) => ['<path $s d="M20 14.5A8.5 8.5 0 019.5 4 8.5 8.5 0 1020 14.5z"/>'],
    'alert': (s) => ['<path $s d="M12 3l10 18H2z"/><path $s d="M12 10v4M12 17h.01"/>'],
    'lock': (s) => ['<rect $s x="5" y="11" width="14" height="10" rx="2"/><path $s d="M8 11V7a4 4 0 118 0v4"/>'],
    'eye': (s) => ['<path $s d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7z"/><circle $s cx="12" cy="12" r="3"/>'],
    'eye-off': (s) => ['<path $s d="M3 3l18 18"/><path $s d="M10.6 5.2A10.6 10.6 0 0112 5c6.4 0 10 7 10 7a17.5 17.5 0 01-3.4 4.3M6.4 6.4A17.6 17.6 0 002 12s3.6 7 10 7a10.4 10.4 0 004.6-1"/><path $s d="M9.9 9.9a3 3 0 004.2 4.2"/>'],
  }.map((k, v) => MapEntry(k, v('stroke="{c}" stroke-width="{w}" fill="none" stroke-linecap="round" stroke-linejoin="round"')));

  @override
  Widget build(BuildContext context) {
    final raw = _paths[name];
    final colorHex = '#${color.value.toRadixString(16).substring(2)}';
    final body = (raw ?? []).join().replaceAll('{c}', colorHex).replaceAll('{w}', strokeWidth.toString());
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="$size" height="$size">$body</svg>';
    if (raw == null) {
      return SizedBox(width: size, height: size);
    }
    return SvgPicture.string(svg, width: size, height: size);
  }
}
