// Mobile/desktop stub: no-op download helper
void downloadBytes(List<int> bytes, String filename) {
  // Intentionally left blank for non-web platforms.
}

void downloadFromUrl(String url, {String? filename}) {
  // On non-web platforms, do nothing for now. Consider url_launcher if needed.
}

