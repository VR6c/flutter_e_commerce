import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/orders_provider.dart';
import '../services/receipt_service.dart';

class ReceiptViewerScreen extends ConsumerStatefulWidget {
  final dynamic orderId;
  final String? receiptUrl;

  const ReceiptViewerScreen({
    super.key,
    required this.orderId,
    this.receiptUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic orderId,
    String? receiptUrl,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptViewerScreen(
          orderId: orderId,
          receiptUrl: receiptUrl,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReceiptViewerScreen> createState() =>
      _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends ConsumerState<ReceiptViewerScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;
  double? _contentHeight;
  List<int>? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _contentHeight = null;
    });

    try {
      final repository = ref.read(orderRepositoryProvider);
      final bytes = await repository.fetchReceiptBytes(widget.orderId);
      _pdfBytes = bytes;

      if (bytes.isEmpty) {
        throw Exception('Empty receipt content received.');
      }

      final isPdf = bytes.length >= 4 &&
          bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46; // F

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'ReceiptChannel',
          onMessageReceived: (JavaScriptMessage message) {
            try {
              final data = jsonDecode(message.message);
              if (data is Map && data['type'] == 'rendered') {
                final h = (data['height'] as num?)?.toDouble();
                if (mounted) {
                  setState(() {
                    if (h != null && h > 100) {
                      _contentHeight = h;
                    }
                    _isLoading = false;
                  });
                }
                return;
              }
            } catch (_) {}
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted && _isLoading) {
                  setState(() => _isLoading = false);
                }
              });
            },
            onWebResourceError: (error) {
              // Ignore non-fatal resource errors
            },
          ),
        );

      if (isPdf) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/order_receipt_${widget.orderId}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        final base64Pdf = base64Encode(bytes);
        final html = _buildPdfJsHtml(base64Pdf);
        await controller.loadHtmlString(html);
      } else {
        final html = utf8.decode(bytes, allowMalformed: true);
        await controller.loadHtmlString(
          _ensureResponsiveViewport(html),
          baseUrl: repository.getReceiptUrl(widget.orderId),
        );
      }

      if (mounted) {
        setState(() {
          _webViewController = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _buildPdfJsHtml(String base64Pdf) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=4.0, user-scalable=yes">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    html, body {
      background-color: #ffffff !important;
      color: #0f172a;
      width: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      -webkit-user-select: none;
      user-select: none;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    #pdf-container {
      width: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 0;
      margin: 0;
      background-color: #ffffff !important;
    }
    canvas {
      width: 100% !important;
      height: auto !important;
      display: block;
      background-color: #ffffff;
      border: none !important;
      outline: none !important;
    }
    #loading {
      color: #64748b;
      padding: 24px;
      font-size: 13px;
      text-align: center;
      background: #ffffff;
    }
  </style>
</head>
<body style="background-color: #ffffff !important;">
  <div id="loading">Loading receipt...</div>
  <div id="pdf-container"></div>
  <script>
    if (typeof pdfjsLib !== 'undefined') {
      pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
    }

    function renderPdf() {
      try {
        const rawData = atob("$base64Pdf");
        const bytes = new Uint8Array(rawData.length);
        for (let i = 0; i < rawData.length; i++) {
          bytes[i] = rawData.charCodeAt(i);
        }

        const loadingTask = pdfjsLib.getDocument({ data: bytes });
        loadingTask.promise.then(function(pdf) {
          const loadingEl = document.getElementById('loading');
          if (loadingEl) loadingEl.style.display = 'none';

          const container = document.getElementById('pdf-container');
          const renderPromises = [];

          for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
            const isLastPage = (pageNum === pdf.numPages);
            const pagePromise = pdf.getPage(pageNum).then(function(page) {
              const dpr = window.devicePixelRatio || 2.5;
              const viewport = page.getViewport({ scale: dpr });

              const tempCanvas = document.createElement('canvas');
              const tempContext = tempCanvas.getContext('2d');
              tempCanvas.height = viewport.height;
              tempCanvas.width = viewport.width;

              return page.render({
                canvasContext: tempContext,
                viewport: viewport
              }).promise.then(function() {
                // Auto-crop empty bottom paper whitespace for the last page
                let cropHeight = tempCanvas.height;
                if (isLastPage) {
                  try {
                    const ctx = tempContext;
                    const w = tempCanvas.width;
                    const h = tempCanvas.height;
                    const imgData = ctx.getImageData(0, 0, w, h).data;
                    let lastY = 0;
                    for (let y = h - 1; y >= 0; y -= 3) {
                      for (let x = 0; x < w; x += 6) {
                        const idx = (y * w + x) * 4;
                        const r = imgData[idx];
                        const g = imgData[idx + 1];
                        const b = imgData[idx + 2];
                        const a = imgData[idx + 3];
                        if (a > 20 && (r < 245 || g < 245 || b < 245)) {
                          lastY = y;
                          break;
                        }
                      }
                      if (lastY > 0) break;
                    }
                    if (lastY > 150 && lastY < h - 20) {
                      cropHeight = Math.min(h, lastY + Math.round(28 * (dpr / 2.0)));
                    }
                  } catch(e) {}
                }

                const finalCanvas = document.createElement('canvas');
                finalCanvas.width = tempCanvas.width;
                finalCanvas.height = cropHeight;
                const finalCtx = finalCanvas.getContext('2d');
                finalCtx.drawImage(tempCanvas, 0, 0);

                container.appendChild(finalCanvas);
              });
            });
            renderPromises.push(pagePromise);
          }

          Promise.all(renderPromises).then(function() {
            // Measure actual height of rendered PDF in CSS pixels
            requestAnimationFrame(function() {
              requestAnimationFrame(function() {
                const container = document.getElementById('pdf-container');
                let totalH = container ? container.getBoundingClientRect().height : 0;
                if (!totalH || totalH < 50) {
                  const canvases = container ? container.querySelectorAll('canvas') : [];
                  totalH = 0;
                  canvases.forEach(function(c) {
                    if (c.width > 0) {
                      const containerW = container.clientWidth || window.innerWidth;
                      totalH += containerW * (c.height / c.width);
                    }
                  });
                }
                if (window.ReceiptChannel) {
                  window.ReceiptChannel.postMessage(JSON.stringify({
                    type: 'rendered',
                    height: Math.ceil(totalH)
                  }));
                }
              });
            });
          });
        }).catch(function(err) {
          console.error('PDF error:', err);
          const loadingEl = document.getElementById('loading');
          if (loadingEl) loadingEl.innerText = 'Could not render preview.';
          if (window.ReceiptChannel) {
            window.ReceiptChannel.postMessage('error');
          }
        });
      } catch (e) {
        console.error('Decode error:', e);
        const loadingEl = document.getElementById('loading');
        if (loadingEl) loadingEl.innerText = 'Could not decode PDF.';
        if (window.ReceiptChannel) {
          window.ReceiptChannel.postMessage('error');
        }
      }
    }

    if (document.readyState === 'complete') {
      renderPdf();
    } else {
      window.addEventListener('load', renderPdf);
    }
  </script>
</body>
</html>
''';
  }

  /// Inject viewport meta tag if missing so the HTML invoice renders sharply on mobile displays
  String _ensureResponsiveViewport(String html) {
    const reportHeightScript = '''
<script>
  window.addEventListener('load', function() {
    setTimeout(function() {
      var h = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
      if (window.ReceiptChannel) {
        window.ReceiptChannel.postMessage(JSON.stringify({ type: 'rendered', height: Math.ceil(h) }));
      }
    }, 100);
  });
</script>
''';
    String modified = html;
    if (!modified.contains('<meta name="viewport"')) {
      const meta =
          '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">';
      if (modified.contains('<head>')) {
        modified = modified.replaceFirst('<head>', '<head>$meta');
      } else if (modified.contains('<html>')) {
        modified = modified.replaceFirst('<html>', '<html><head>$meta</head>');
      } else {
        modified = '<!DOCTYPE html><html><head>$meta</head><body>$modified</body></html>';
      }
    }
    if (modified.contains('</body>')) {
      modified = modified.replaceFirst('</body>', '$reportHeightScript</body>');
    } else {
      modified = '$modified$reportHeightScript';
    }
    return modified;
  }

  Future<void> _downloadReceipt() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final file = await ReceiptService.downloadReceipt(
        context: context,
        ref: ref,
        orderId: widget.orderId,
        existingBytes: _pdfBytes,
        fromViewerScreen: true,
      );
      if (file != null && mounted) {
        ReceiptService.showFileDetailsBottomSheet(
          context,
          orderId: widget.orderId,
          file: file,
          fromViewerScreen: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.orderReceipt,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildContent(theme, isDark, l10n),
            ),
            // Bottom Action Bar
            _buildBottomBar(theme, isDark, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadingReceipt,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.failedToLoadReceipt,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseTryAgainOrOpen,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadReceipt,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(l10n.close),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_webViewController != null) {
      final defaultHeight = MediaQuery.of(context).size.height * 0.65;
      final targetHeight = _contentHeight ?? defaultHeight;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            height: targetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: WebViewWidget(controller: _webViewController!),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadReceipt,
          icon: _isDownloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.file_download_outlined, size: 20),
          label: Text(
            _isDownloading
                ? (l10n.downloading)
                : l10n.downloadReceipt,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
