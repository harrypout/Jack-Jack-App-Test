/// Display older advertised names and stored history using the current brand.
/// Device identifiers and stored records are left intact.
String displayDeviceName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Jack Jack';
  return trimmed.replaceAll(
    RegExp(r'\bpebble\b', caseSensitive: false),
    'Jack Jack',
  );
}
