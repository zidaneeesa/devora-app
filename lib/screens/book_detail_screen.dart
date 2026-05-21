import 'package:flutter/material.dart';
import 'book_reader_screen.dart';
import 'ebook_web_reader_screen.dart';
import '../../services/api_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final bool isEbook;

  const BookDetailScreen({super.key, required this.book, this.isEbook = false});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  double progress = 0.0;
  int currentPage = 0;
  int totalPage = 0;
  Map<String, dynamic>? detailBook;
  bool isLoadingDetail = true;

  String _safeText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String? _safeImageUrl(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;

    return text;
  }

  String? _getCategoryName() {
    final category = widget.book['category'];

    if (category == null) return null;

    if (category is Map) {
      return category['name']?.toString();
    }

    return category.toString();
  }

  String? _getPublisherName() {
    final publisher = widget.book['publisher'];

    if (publisher == null) return null;

    if (publisher is Map) {
      return publisher['name']?.toString();
    }

    return publisher.toString();
  }

  String? _cleanUrl(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;

    return text;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;

    return int.tryParse(text) ?? fallback;
  }

  int _getBestPageCount(Map<String, dynamic> source) {
    final candidates = [
      source['pages'],
      source['page_count'],
      source['pageCount'],
      source['imagecount'],
      source['total_page'],
      source['total_pages'],
    ];

    for (final candidate in candidates) {
      final value = _asInt(candidate);
      if (value > 0) return value;
    }

    return 0;
  }

  bool _isValidPdfUrl(dynamic value) {
    final url = _cleanUrl(value);
    if (url == null) return false;

    String decodedUrl = url;

    try {
      decodedUrl = Uri.decodeFull(url);
    } catch (_) {}

    final lower = decodedUrl.toLowerCase().trim();
    final withoutQuery = lower.split('?').first;

    if (!lower.startsWith('http')) return false;

    // Harus PDF
    if (!lower.contains('.pdf')) return false;

    // Hindari file backup/history Internet Archive
    if (lower.contains('/history/files/')) return false;
    if (lower.contains('.pdf.~')) return false;
    if (lower.endsWith('~')) return false;

    // Pastikan path utama berakhir .pdf
    if (!withoutQuery.endsWith('.pdf')) return false;

    return true;
  }

  String? _pickValidPdfUrlFrom(dynamic source) {
    if (source == null || source is! Map) return null;

    // Prioritas pertama dari pdf_link
    final directPdf = _cleanUrl(source['pdf_link']);
    if (_isValidPdfUrl(directPdf)) {
      return directPdf;
    }

    // Lalu cari dari formats
    final formats = source['formats'];
    if (formats != null && formats is Map) {
      for (final entry in formats.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = _cleanUrl(entry.value);

        if (key.contains('pdf') && _isValidPdfUrl(value)) {
          return value;
        }
      }
    }

    return null;
  }

  String? _pickWebReaderUrlFrom(dynamic source) {
    if (source == null || source is! Map) return null;

    final webReader = _cleanUrl(source['web_reader']);
    if (webReader != null && webReader.startsWith('http')) {
      return webReader;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEbook) {
      fetchProgress();
    } else {
      fetchBookDetail();
    }
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  int _resolveTotalPages([dynamic detail]) {
    final sources = [detail, widget.book];

    for (final source in sources) {
      if (source is Map) {
        final keys = [
          'pages',
          'page_count',
          'pageCount',
          'imagecount',
          'total_page',
        ];

        for (final key in keys) {
          final value = _readInt(source[key]);
          if (value > 0) return value;
        }
      }
    }

    if (totalPage > 0) return totalPage;

    return 0;
  }

  Future<void> fetchProgress() async {
    try {
      final res = await ApiService.getReadingProgress(
        widget.book['id'].toString(),
      );

      if (!mounted) return;

      if (res['status'] == 200 && res['data'] != null) {
        final int newCurrentPage =
            int.tryParse('${res['data']['current_page'] ?? 0}') ?? 0;

        final int newTotalPage =
            int.tryParse('${res['data']['total_page'] ?? 0}') ?? 0;

        setState(() {
          currentPage = newCurrentPage;
          totalPage = newTotalPage;
          progress = newTotalPage == 0 ? 0 : newCurrentPage / newTotalPage;
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil progress: $e');
    }
  }

  Future<void> fetchBookDetail() async {
    final res = await ApiService.getBookDetail(widget.book['id'].toString());

    if (res['status'] == 200) {
      setState(() {
        detailBook = res['data'];
        isLoadingDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Gradient + Book Cover)
            Container(
              padding: const EdgeInsets.only(top: 100, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFD6E3DB),
                    const Color(0xFFF7FAF8).withOpacity(0.0),
                  ],
                ),
              ),
              child: Center(
                child: Builder(
                  builder: (context) {
                    final titleStr = _safeText(
                      widget.book['title'],
                      fallback: 'B',
                    );
                    final initials = titleStr.length > 1
                        ? titleStr.substring(0, 2).toUpperCase()
                        : titleStr.toUpperCase();

                    final coverImage = _safeImageUrl(
                      widget.book['cover_image'],
                    );

                    return Container(
                      height: 280,
                      width: 190,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: coverImage != null
                            ? DecorationImage(
                                image: NetworkImage(coverImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: coverImage == null
                          ? Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(
                                    0xFF2B5A41,
                                  ).withOpacity(0.3),
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(widget.book['title'], fallback: 'Tanpa Judul'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _safeText(
                      widget.book['author'],
                      fallback: 'Unknown Author',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5A41),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatPill(
                        Icons.star,
                        widget.book['avg_rating']?.toString() ?? '4.8',
                        'RATING',
                        Colors.orange,
                      ),
                      _buildStatPill(
                        Icons.library_books,
                        widget.book['pages']?.toString() ?? '324',
                        'HALAMAN',
                        Colors.black87,
                      ),
                      if (!widget.isEbook)
                        _buildStatPill(
                          Icons.inventory_2,
                          '${widget.book['stock'] ?? 0}',
                          'TERSEDIA',
                          const Color(0xFF2B5A41),
                        )
                      else
                        _buildStatPill(
                          Icons.download,
                          '140',
                          'DIUNDUH',
                          const Color(0xFF2B5A41),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _safeText(
                      widget.book['synopsis'] ?? widget.book['description'],
                      fallback:
                          'Buku ini tidak memiliki sinopsis. Namun, dipastikan buku ini sangat menarik untuk dibaca dan menambah wawasan Anda di perpustakaan Devora Atheneum.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  // Tags
                  Builder(
                    builder: (context) {
                      final categoryName = _getCategoryName();
                      final publisherName = _getPublisherName();

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (categoryName != null &&
                              categoryName.trim().isNotEmpty)
                            _buildTag(categoryName.toUpperCase()),
                          if (publisherName != null &&
                              publisherName.trim().isNotEmpty)
                            _buildTag(publisherName.toUpperCase()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  if (!widget.isEbook &&
                      detailBook?['copies'] != null &&
                      detailBook?['copies'].isNotEmpty) ...[
                    const Text(
                      'Daftar Eksemplar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...List.generate(detailBook?['copies'].length, (index) {
                      final copy = detailBook?['copies'][index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  copy['copy_code'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Kondisi: ${copy['condition']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F5EC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                copy['status'],
                                style: const TextStyle(
                                  color: Color(0xFF2B5A41),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(
                    height: 120,
                  ), // padding for floating bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: widget.isEbook
          ? Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEbook) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress Membaca',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("${(progress * 100).toInt()}%"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEbook ? 'FORMAT' : 'KETERSEDIAAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isEbook
                                ? 'E-Book Digital'
                                : '${widget.book['stock'] ?? 0} Copy Fisik',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.isEbook)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!widget.isEbook) return;

                                final id = widget.book['id']?.toString() ?? '';

                                if (id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Data ebook tidak valid'),
                                    ),
                                  );
                                  return;
                                }

                                if (id.contains('http')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ebook tidak bisa dibuka'),
                                    ),
                                  );
                                  return;
                                }

                                if (id.toLowerCase().contains('mp3')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ini file audio, bukan ebook',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                String? pdfUrl = _pickValidPdfUrlFrom(
                                  widget.book,
                                );
                                String? webReaderUrl = _pickWebReaderUrlFrom(
                                  widget.book,
                                );
                                Map<String, dynamic>? detail;

                                try {
                                  final source =
                                      widget.book['source']?.toString() ??
                                      'internet_archive';

                                  final res = await ApiService.getEbookDetail(
                                    id,
                                    source: source,
                                  );

                                  if (res['status'] == 200 &&
                                      res['data'] != null) {
                                    detail = Map<String, dynamic>.from(
                                      res['data'],
                                    );

                                    final detailPdf = _pickValidPdfUrlFrom(
                                      detail,
                                    );
                                    final detailWebReader =
                                        _pickWebReaderUrlFrom(detail);

                                    if (detailPdf != null) {
                                      pdfUrl = detailPdf;
                                    }

                                    if (detailWebReader != null) {
                                      webReaderUrl = detailWebReader;
                                    }
                                  }
                                } catch (e) {
                                  debugPrint(
                                    'Gagal mengambil detail ebook: $e',
                                  );
                                }

                                final int totalPages = _resolveTotalPages(
                                  detail,
                                );

                                debugPrint('VALID PDF URL: $pdfUrl');
                                debugPrint('WEB READER URL: $webReaderUrl');
                                debugPrint('TOTAL PAGES: $totalPages');

                                // Prioritas utama: Web Reader
                                if (webReaderUrl != null &&
                                    webReaderUrl.isNotEmpty) {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EbookWebReaderScreen(
                                        url: webReaderUrl!,
                                        title: widget.book['title'] ?? '',
                                        ebookId: id,
                                        totalPages: totalPages,
                                        pdfUrl: pdfUrl,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;

                                  if (result == true) {
                                    await fetchProgress();
                                  } else {
                                    await fetchProgress();
                                  }

                                  return;
                                }

                                // Fallback: PDF Reader
                                if (pdfUrl != null && pdfUrl.isNotEmpty) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookReaderScreen(
                                        url: pdfUrl!,
                                        title: widget.book['title'] ?? '',
                                        ebookId: id,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;
                                  await fetchProgress();
                                  return;
                                }

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ebook belum tersedia untuk dibaca',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF679B7B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.isEbook
                                    ? 'Mulai Membaca'
                                    : 'Lihat Koleksi',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildStatPill(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
