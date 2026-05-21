import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../../services/api_service.dart';

class BookReaderScreen extends StatefulWidget {
  final String url;
  final String title;
  final String ebookId;
  final int initialPage;

  const BookReaderScreen({
    super.key,
    required this.url,
    required this.title,
    required this.ebookId,
    this.initialPage = 1,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final PdfViewerController _pdfController;
  late Future<Uint8List> _pdfFuture;
  late Future<int> _lastPageFuture;

  @override
  void initState() {
    super.initState();

    _pdfController = PdfViewerController();
    _pdfFuture = loadPdf();
    _lastPageFuture = loadLastPage();
  }

  String _normalizePdfUrl(String url) {
    var cleanUrl = url.trim();

    try {
      cleanUrl = Uri.decodeFull(cleanUrl);
    } catch (_) {}

    cleanUrl = cleanUrl.replaceAll(' ', '%20');

    return cleanUrl;
  }

  Future<Uint8List> loadPdf() async {
    try {
      final fixedUrl = _normalizePdfUrl(widget.url);

      debugPrint("RAW URL: ${widget.url}");
      debugPrint("FIXED URL: $fixedUrl");

      final response = await http.get(
        Uri.parse(fixedUrl),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/pdf,*/*'},
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("CONTENT TYPE: ${response.headers['content-type']}");
      debugPrint("SIZE: ${response.bodyBytes.length}");

      if (response.statusCode != 200) {
        throw Exception("Server menolak PDF. Status: ${response.statusCode}");
      }

      final header = response.bodyBytes.length >= 4
          ? String.fromCharCodes(response.bodyBytes.take(4))
          : '';

      if (header != '%PDF') {
        throw Exception("File ini bukan PDF valid atau PDF tidak tersedia.");
      }

      return response.bodyBytes;
    } catch (e) {
      debugPrint("ERROR LOAD PDF: $e");
      throw Exception("Gagal memuat PDF. Kemungkinan PDF tidak tersedia.");
    }
  }

  Future<int> loadLastPage() async {
    try {
      final res = await ApiService.getReadingProgress(widget.ebookId);

      if (res['status'] == 200 && res['data'] != null) {
        final page = int.tryParse('${res['data']['current_page'] ?? 1}') ?? 1;
        return page < 1 ? 1 : page;
      }
    } catch (e) {
      debugPrint('Gagal mengambil progress PDF: $e');
    }

    return widget.initialPage < 1 ? 1 : widget.initialPage;
  }

  Future<void> _jumpToLastPage(int pageCount) async {
    final savedPage = await _lastPageFuture;

    int targetPage = savedPage;

    if (widget.initialPage > targetPage) {
      targetPage = widget.initialPage;
    }

    if (targetPage < 1) targetPage = 1;
    if (targetPage > pageCount) targetPage = pageCount;

    if (targetPage > 1) {
      _pdfController.jumpToPage(targetPage);
    }
  }

  Future<void> _saveProgress(int currentPage, int totalPage) async {
    if (totalPage <= 0) return;

    final progress = currentPage / totalPage;

    debugPrint("PDF PROGRESS SAVED: $currentPage / $totalPage");

    await ApiService.updateReadingProgress(
      widget.ebookId,
      progress,
      currentPage,
      totalPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF679B7B),
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF679B7B)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 72,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "PDF Tidak Tersedia",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pdfFuture = loadPdf();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Coba Lagi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF679B7B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SfPdfViewer.memory(
            snapshot.data!,
            controller: _pdfController,
            onDocumentLoaded: (details) async {
              await _jumpToLastPage(_pdfController.pageCount);
            },
            onPageChanged: (details) {
              final currentPage = details.newPageNumber;
              final totalPage = _pdfController.pageCount;

              _saveProgress(currentPage, totalPage);
            },
          );
        },
      ),
    );
  }
}
