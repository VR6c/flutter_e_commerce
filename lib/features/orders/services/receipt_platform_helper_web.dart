import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

void platformDownloadBytes(List<int> bytes, String fileName, String mimeType) {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

void platformOpenInNewTab(List<int> bytes, String mimeType) {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
}

class WebReceiptViewer extends StatefulWidget {
  final List<int> bytes;
  final bool isPdf;
  final String? rawHtml;

  const WebReceiptViewer({
    super.key,
    required this.bytes,
    required this.isPdf,
    this.rawHtml,
  });

  @override
  State<WebReceiptViewer> createState() => _WebReceiptViewerState();
}

class _WebReceiptViewerState extends State<WebReceiptViewer> {
  late final String _viewId;
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    _viewId = 'receipt-frame-${DateTime.now().microsecondsSinceEpoch}';
    final mime = widget.isPdf ? 'application/pdf' : 'text/html';
    final uint8List = Uint8List.fromList(widget.bytes);
    final blob = web.Blob(
      [uint8List.toJS].toJS,
      web.BlobPropertyBag(type: mime),
    );
    _blobUrl = web.URL.createObjectURL(blob);

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = _blobUrl!;
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      return iframe;
    });
  }

  @override
  void dispose() {
    if (_blobUrl != null) {
      web.URL.revokeObjectURL(_blobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}

Widget buildWebReceiptViewer({
  required List<int> bytes,
  required bool isPdf,
  String? rawHtml,
}) {
  return WebReceiptViewer(
    bytes: bytes,
    isPdf: isPdf,
    rawHtml: rawHtml,
  );
}
