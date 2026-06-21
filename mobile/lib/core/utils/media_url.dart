/// Resuelve URLs de imágenes del backend Laravel (/storage/...).
String resolveMediaUrl(String? url, String apiBaseUrl) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  final origin = apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/$url';
}
