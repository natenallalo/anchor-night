/// Web / non-IO: real filesystem files are unavailable, but blob/http URLs are valid.
bool fileExists(String path) {
  final p = path.trim();
  if (p.isEmpty) return false;
  return p.startsWith('blob:') ||
      p.startsWith('http://') ||
      p.startsWith('https://') ||
      p.startsWith('data:');
}
