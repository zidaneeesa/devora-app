import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/api_service.dart';
import 'book_reader_screen.dart';

class EbookWebReaderScreen extends StatefulWidget {
  final String url;
  final String title;
  final String ebookId;
  final int totalPages;
  final String? pdfUrl;

  const EbookWebReaderScreen({
    super.key,
    required this.url,
    required this.title,
    required this.ebookId,
    required this.totalPages,
    this.pdfUrl,
  });

  @override
  State<EbookWebReaderScreen> createState() => _EbookWebReaderScreenState();
}

class _EbookWebReaderScreenState extends State<EbookWebReaderScreen> {
  late final WebViewController _controller;

  Timer? _progressTimer;
  Timer? _slowLoadTimer;

  int loadingProgress = 0;
  int _currentPage = 1;
  int _totalPages = 0;
  double _progress = 0.0;
  int _lastSavedPage = 0;
  bool _pageFinished = false;
  bool _isClosing = false;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();

    // Jangan default 100. Kalau belum tahu, biarkan 0 dulu.
    _totalPages = widget.totalPages > 0 ? widget.totalPages : 0;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              loadingProgress = progress;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;

            setState(() {
              _pageFinished = true;
              _showSlowHint = false;
            });

            _startProgressTracker();

            // Baca progress sekali setelah halaman selesai load.
            await Future.delayed(const Duration(seconds: 2));
            await _detectCurrentPageFromWebReader(forceSave: true);
          },
          onWebResourceError: (error) {
            // Jangan tampilkan popup dari error resource kecil Archive.org.
            // Banyak error seperti sentry/audio/asset yang tidak mengganggu reader utama.
            debugPrint('WEB READER RESOURCE ERROR: ${error.description}');
          },
        ),
      );

    _loadReaderWithLastProgress();
    _startSlowLoadChecker();
  }

  void _startSlowLoadChecker() {
    _slowLoadTimer?.cancel();

    _slowLoadTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted) return;

      // Jangan langsung fallback otomatis karena kadang reader sudah tampil
      // tapi progress loading belum 100 akibat resource Archive.org.
      if (!_pageFinished && loadingProgress < 80) {
        setState(() {
          _showSlowHint = true;
        });
      }
    });
  }

  Future<void> _loadReaderWithLastProgress() async {
    int lastPage = 1;

    try {
      final res = await ApiService.getReadingProgress(widget.ebookId);

      if (res['status'] == 200 && res['data'] != null) {
        lastPage = int.tryParse('${res['data']['current_page'] ?? 1}') ?? 1;

        final savedTotal =
            int.tryParse('${res['data']['total_page'] ?? 0}') ?? 0;

        if (_totalPages <= 0 && savedTotal > 0) {
          _totalPages = savedTotal;
        }
      }
    } catch (e) {
      debugPrint('Gagal ambil progress terakhir web reader: $e');
    }

    if (lastPage < 1) lastPage = 1;
    if (_totalPages > 0 && lastPage > _totalPages) {
      lastPage = _totalPages;
    }

    final fixedUrl = _buildUrlWithPage(widget.url, lastPage);

    debugPrint('WEB READER URL: $fixedUrl');

    await _controller.loadRequest(Uri.parse(fixedUrl));

    await _saveProgress(lastPage);
  }

  String _buildUrlWithPage(String url, int page) {
    final baseUrl = url.split('#').first;

    // Internet Archive pakai index mulai dari 0.
    final pageIndex = page <= 1 ? 0 : page - 1;

    return '$baseUrl#page/n$pageIndex/mode/1up';
  }

  void _startProgressTracker() {
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _detectCurrentPageFromWebReader();
    });
  }

  Future<void> _detectCurrentPageFromWebReader({bool forceSave = false}) async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var pageIndex = -1;
          var totalPages = 0;

          try {
            if (window.br) {
              if (typeof window.br.currentIndex === 'function') {
                pageIndex = window.br.currentIndex();
              }

              if (typeof window.br.getNumLeafs === 'function') {
                totalPages = window.br.getNumLeafs();
              } else if (window.br.numLeafs) {
                totalPages = window.br.numLeafs;
              } else if (window.br.book && window.br.book.numLeafs) {
                totalPages = window.br.book.numLeafs;
              }
            }
          } catch(e) {}

          try {
            if (pageIndex < 0) {
              var hash = window.location.hash || "";
              var match = hash.match(/page\\/n(\\d+)/);
              if (match && match[1]) {
                pageIndex = parseInt(match[1]);
              }
            }
          } catch(e) {}

          var scrollPercent = 0;

          try {
            var doc = document.documentElement;
            var body = document.body;

            var scrollTop = window.scrollY || doc.scrollTop || body.scrollTop || 0;

            var scrollHeight = Math.max(
              body.scrollHeight,
              doc.scrollHeight,
              body.offsetHeight,
              doc.offsetHeight,
              body.clientHeight,
              doc.clientHeight
            );

            var height = window.innerHeight || doc.clientHeight;
            var maxScroll = scrollHeight - height;

            if (maxScroll > 0) {
              scrollPercent = Math.round((scrollTop / maxScroll) * 100);
            }
          } catch(e) {}

          return pageIndex + "|" + scrollPercent + "|" + totalPages;
        })();
      ''');

      final text = _cleanJsResult(result);
      final parts = text.split('|');

      final int pageIndex = parts.isNotEmpty
          ? int.tryParse(parts[0]) ?? -1
          : -1;

      final int scrollPercent = parts.length > 1
          ? int.tryParse(parts[1]) ?? 0
          : 0;

      final int detectedTotal = parts.length > 2
          ? int.tryParse(parts[2]) ?? 0
          : 0;

      if (detectedTotal > 0 && detectedTotal != _totalPages) {
        setState(() {
          _totalPages = detectedTotal;
        });
      }

      int detectedPage;

      if (pageIndex >= 0) {
        detectedPage = pageIndex + 1;
      } else if (_totalPages > 0) {
        detectedPage = ((_totalPages * scrollPercent) / 100).round();
        if (detectedPage < 1) detectedPage = 1;
      } else {
        detectedPage = _currentPage;
      }

      if (detectedPage < 1) detectedPage = 1;
      if (_totalPages > 0 && detectedPage > _totalPages) {
        detectedPage = _totalPages;
      }

      if (forceSave || detectedPage != _lastSavedPage) {
        await _saveProgress(detectedPage);
      }
    } catch (e) {
      debugPrint('Gagal membaca progress web reader: $e');
    }
  }

  String _cleanJsResult(Object? value) {
    var text = value?.toString() ?? '';

    if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    }

    return text.replaceAll(r'\"', '"').trim();
  }

  Future<void> _saveProgress(int page) async {
    if (page < 1) page = 1;

    final int safeTotalPage = _totalPages > 0 ? _totalPages : page;
    final double progress = safeTotalPage <= 0 ? 0 : page / safeTotalPage;

    if (!mounted) return;

    setState(() {
      _currentPage = page;
      _progress = progress.clamp(0.0, 1.0);
      _lastSavedPage = page;
    });

    await ApiService.updateReadingProgress(
      widget.ebookId,
      _progress,
      page,
      safeTotalPage,
    );

    debugPrint('WEB PROGRESS SAVED: $page / $safeTotalPage');
  }

  Future<bool> _handleBack() async {
    if (_isClosing) return false;

    _isClosing = true;

    await _detectCurrentPageFromWebReader(forceSave: true);
    await _saveProgress(_currentPage);

    if (mounted) {
      Navigator.pop(context, true);
    }

    return false;
  }

  void _openPdfFallback() {
    final pdfUrl = widget.pdfUrl;

    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF tidak tersedia untuk ebook ini')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(
          url: pdfUrl,
          title: widget.title,
          ebookId: widget.ebookId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalText = _totalPages > 0 ? '$_totalPages' : '...';
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF679B7B),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Buka PDF',
              onPressed: _openPdfFallback,
              icon: const Icon(Icons.picture_as_pdf),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.35),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Halaman $_currentPage / $totalText • $percent%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),

            if (loadingProgress < 100)
              LinearProgressIndicator(
                value: loadingProgress / 100,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF2B5A41),
              ),

            if (_showSlowHint)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF679B7B),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Reader masih memuat. Jika kosong, coba reload atau buka PDF.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showSlowHint = false;
                              loadingProgress = 0;
                              _pageFinished = false;
                            });

                            _controller.reload();
                            _startSlowLoadChecker();
                          },
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
