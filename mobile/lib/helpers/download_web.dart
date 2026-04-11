import 'dart:convert';
import 'dart:html' as html;

void downloadCsv(String csv, String filename) {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
