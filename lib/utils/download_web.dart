// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBytes(List<int> bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void downloadFromUrl(String url, {String? filename}) {
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none';
  if (filename != null && filename.isNotEmpty) {
    anchor.download = filename;
  }
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
}

