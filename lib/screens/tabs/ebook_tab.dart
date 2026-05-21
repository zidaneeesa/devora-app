import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class EbookTab extends StatefulWidget {
  const EbookTab({super.key});

  @override
  State<EbookTab> createState() => _EbookTabState();
}

class _EbookTabState extends State<EbookTab> {
  List<dynamic> _books = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;
  final Set<String> _savedBookKeys = {};
  String _nik = '';
  bool _isCollectionLoading = false;

  @override
  void initState() {
    super.initState();
    _initCollection();
    _fetchBooks(_searchQuery);
  }

  void _fetchBooks(String query) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final res = await ApiService.getEbooks(query, source: 'all');

    if (!mounted) return;

    if (res['status'] == 200) {
      setState(() {
        _books = res['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);

      showMsg(res['message']?.toString() ?? 'Gagal mengambil data e-book');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _fetchBooks(query);
    });
  }

  String _ebookId(dynamic book) {
    final id =
        book['id'] ??
        book['book_id'] ??
        book['id_buku'] ??
        book['isbn'] ??
        book['title'];

    return id?.toString() ?? '';
  }

  String _collectionKey(dynamic book) {
    return 'ebook:${_ebookId(book)}';
  }

  Future<void> _initCollection() async {
    final prefs = await SharedPreferences.getInstance();

    _nik =
        prefs.getString('nik') ??
        prefs.getString('user_nik') ??
        prefs.getString('NIK') ??
        '';

    if (_nik.isEmpty) {
      final profileRes = await ApiService.getProfile();

      if (profileRes['status'] == 200) {
        final user = profileRes['data']?['user'];
        final member = user is Map ? user['member'] : null;

        _nik = member is Map
            ? (member['nik']?.toString() ?? '')
            : (user is Map ? user['nik']?.toString() ?? '' : '');
      }
    }

    if (_nik.isEmpty) return;

    await _loadSavedEbookIds();
  }

  Future<void> _loadSavedEbookIds() async {
    if (_nik.isEmpty) return;

    final res = await ApiService.getBookCollections(_nik);

    if (!mounted) return;

    if (res['status'] == 200) {
      final data = List<Map<String, dynamic>>.from(
        (res['data'] ?? []).map((item) {
          return Map<String, dynamic>.from(item);
        }),
      );

      setState(() {
        _savedBookKeys
          ..clear()
          ..addAll(
            data
                .where((item) => item['collection_type'] == 'ebook')
                .map((item) {
                  final id = (item['book_id'] ?? item['id'] ?? '').toString();
                  return 'ebook:$id';
                })
                .where((key) => !key.endsWith(':')),
          );
      });
    }
  }

  Future<void> _toggleEbookCollection(dynamic book) async {
    if (_nik.isEmpty) {
      showMsg('NIK user tidak ditemukan. Silakan login ulang.');
      return;
    }

    if (_isCollectionLoading) return;

    final id = _ebookId(book);
    if (id.isEmpty) return;

    final key = _collectionKey(book);
    final isSaved = _savedBookKeys.contains(key);

    setState(() {
      _isCollectionLoading = true;
    });

    final Map<String, dynamic> res = isSaved
        ? await ApiService.deleteBookCollection(
            nik: _nik,
            bookId: id,
            collectionType: 'ebook',
          )
        : await ApiService.addBookCollection(
            nik: _nik,
            collectionType: 'ebook',
            book: {
              ...Map<String, dynamic>.from(book),
              'book_id': id,
              'collection_type': 'ebook',
            },
          );

    if (!mounted) return;

    setState(() {
      _isCollectionLoading = false;

      if (res['status'] == 200) {
        if (isSaved) {
          _savedBookKeys.remove(key);
        } else {
          _savedBookKeys.add(key);
        }
      }
    });

    showMsg(
      res['status'] == 200
          ? isSaved
                ? 'E-book dihapus dari koleksi'
                : 'E-book berhasil disimpan'
          : res['message']?.toString() ?? 'Terjadi kesalahan',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // 🔥 helper snackbar
  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 FILTER RINGAN (biar tetap banyak tapi bersih)
    final filteredBooks = _books;

    return Container(
      color: const Color(0xFFF7FAF8),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari jutaan buku digital...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: const Color(0xFFF7FAF8),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                ? const Center(child: Text('Tidak ada e-book ditemukan.'))
                : RefreshIndicator(
                    onRefresh: () async => _fetchBooks(_searchQuery),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        final isSaved = _savedBookKeys.contains(
                          _collectionKey(book),
                        );

                        return GestureDetector(
                          onTap: () async {
                            final id = book['id']?.toString() ?? '';
                            final source =
                                book['source']?.toString() ??
                                'internet_archive';

                            if (id.isEmpty) {
                              showMsg('Data e-book tidak valid');
                              return;
                            }

                            final res = await ApiService.getEbookDetail(
                              id,
                              source: source,
                            );

                            debugPrint('DETAIL EBOOK RESPONSE: $res');

                            if (res['status'] != 200 || res['data'] == null) {
                              showMsg('Gagal mengambil detail e-book');
                              return;
                            }

                            final detail = Map<String, dynamic>.from(
                              res['data'],
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(
                                  book: {
                                    ...Map<String, dynamic>.from(book),
                                    ...detail,
                                    'source': source,
                                  },
                                  isEbook: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          image: book['cover_image'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    book['cover_image'],
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: book['cover_image'] == null
                                            ? const Center(
                                                child: Icon(
                                                  Icons.book,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _toggleEbookCollection(book),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: isSaved
                                                  ? Colors.blue.shade700
                                                  : Colors.white.withValues(
                                                      alpha: 0.94,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.10),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isSaved
                                                  ? Icons.bookmark_rounded
                                                  : Icons
                                                        .bookmark_border_rounded,
                                              size: 19,
                                              color: isSaved
                                                  ? Colors.white
                                                  : Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['title'] ?? 'Tanpa Judul',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        book['author'] ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'E-BOOK',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
