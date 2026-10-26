import 'package:flutter/widgets.dart';

void platformDownloadBytes(List<int> bytes, String fileName, String mimeType) {
  // Stub: On mobile, files are handled via path_provider and dart:io.
}

void platformOpenInNewTab(List<int> bytes, String mimeType) {
  // Stub: Not applicable for mobile platforms.
}

Widget buildWebReceiptViewer({
  required List<int> bytes,
  required bool isPdf,
  String? rawHtml,
}) {
  return const SizedBox.shrink();
}
