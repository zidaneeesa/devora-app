import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';
import 'ebook_tab.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  List<dynamic> _books = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'Semua';

  // Pagination states
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  final Set<String> _savedBookKeys = {};
  List<Map<String, dynamic>> _bookCollections = [];
  String _nik = '';
  bool _isCollectionLoading = false;

  @override
  void initState() {
    super.initState();
    _initCollection();
    _fetchBooks();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchBooks({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _books = [];
        _hasMore = true;
        _isLoading = true;
      });
    }

    if (!_hasMore) return;

    final res = await ApiService.getBooks(
      page: _page,
      q: _searchQuery,
      sort: _activeFilter,
    );
    if (res['status'] == 200 && mounted) {
      final newBooks = res['data']['data'] ?? [];
      setState(() {
        _books.addAll(newBooks);
        _isLoading = false;
        _isLoadingMore = false;

        if (newBooks.length < 20) {
          _hasMore = false;
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_hasMore && !_isLoadingMore && !_isLoading) {
      setState(() {
        _isLoadingMore = true;
        _page++;
      });
      _fetchBooks();
    }
  }

  void _filterBooks(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _fetchBooks(reset: true);
      }
    });
  }

  void _onFilterChanged(String filter) {
    if (_activeFilter == filter) return;
    setState(() {
      _activeFilter = filter;
    });
    _fetchBooks(reset: true);
  }

  Widget _buildSearchBarWithDropdown() {
    final filters = ['Semua', 'Terbaru', 'Populer'];

    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2B5A41).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B5A41).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF2B5A41), size: 24),
          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              onChanged: _filterBooks,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Cari judul buku...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          const SizedBox(width: 8),

          PopupMenuButton<String>(
            tooltip: 'Filter buku',
            color: const Color(0xFF2B5A41),
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              _onFilterChanged(value);
            },
            itemBuilder: (context) {
              final filters = ['Semua', 'Terbaru', 'Populer'];

              return filters.map((filter) {
                final isSelected = _activeFilter == filter;

                return PopupMenuItem<String>(
                  value: filter,
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 17,
                        color: isSelected
                            ? const Color(0xFFF4B740)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        filter,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F4D36), Color(0xFF2B5A41)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B5A41).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeFilter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter Buku',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih urutan katalog buku yang ingin ditampilkan.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),

              _buildFilterSheetItem(
                label: 'Semua',
                icon: Icons.grid_view_rounded,
              ),
              _buildFilterSheetItem(
                label: 'Terbaru',
                icon: Icons.new_releases_rounded,
              ),
              _buildFilterSheetItem(
                label: 'Populer',
                icon: Icons.local_fire_department_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  String _bookId(dynamic book) {
    final id =
        book['id'] ??
        book['book_id'] ??
        book['id_buku'] ??
        book['isbn'] ??
        book['title'];

    return id?.toString() ?? '';
  }

  String _collectionKey(dynamic book, String type) {
    return '$type:${_bookId(book)}';
  }

  Future<void> _openSavedBooksSheet() async {
    if (_nik.isEmpty) {
      await _initCollection();
    }

    await _loadSavedBookIds();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bookmarks_rounded,
                        color: Color(0xFF2B5A41),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Buku Tersimpan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: const Color(0xFF2B5A41).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: const Color(0xFF2B5A41),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        text:
                            'Buku Perpus (${_bookCollections.where((e) => (e['collection_type'] ?? 'catalog') == 'catalog').length})',
                      ),
                      Tab(
                        text:
                            'E-Book (${_bookCollections.where((e) => e['collection_type'] == 'ebook').length})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSavedBookList('catalog'),
                      _buildSavedBookList('ebook'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSheetItem({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeFilter == label;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pop(context);
        _onFilterChanged(label);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F1EC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B5A41) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2B5A41)
                    : const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF2B5A41),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? const Color(0xFF2B5A41)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2B5A41)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBookList(String type) {
    final books = _bookCollections.where((book) {
      final bookType = book['collection_type']?.toString() ?? 'catalog';
      return bookType == type;
    }).toList();

    if (books.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'ebook'
                    ? Icons.tablet_mac_rounded
                    : Icons.local_library_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                type == 'ebook'
                    ? 'Belum ada e-book tersimpan'
                    : 'Belum ada buku perpus tersimpan',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = books[index];
        final cover = book['cover_image']?.toString() ?? '';
        final title = book['title']?.toString() ?? 'Tanpa Judul';
        final author = book['author']?.toString() ?? '-';

        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            _openSavedBookDetail(book);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1EC),
                    borderRadius: BorderRadius.circular(16),
                    image: cover.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(cover),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cover.isEmpty
                      ? Icon(
                          type == 'ebook'
                              ? Icons.tablet_mac_rounded
                              : Icons.menu_book_rounded,
                          color: const Color(0xFF2B5A41),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: type == 'ebook'
                              ? Colors.blue.shade50
                              : const Color(0xFFE8F1EC),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          type == 'ebook' ? 'E-BOOK' : 'BUKU PERPUS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: type == 'ebook'
                                ? Colors.blue.shade700
                                : const Color(0xFF2B5A41),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2B5A41),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSavedBookDetail(Map<String, dynamic> book) async {
    final type = book['collection_type']?.toString() ?? 'catalog';

    if (type == 'ebook') {
      String clean(dynamic value) {
        final text = value?.toString().trim() ?? '';
        if (text.isEmpty || text == 'null' || text == '-') return '';
        return text;
      }

      String? archiveIdFromWebReader(String url) {
        final match = RegExp(r'archive\.org/embed/([^?#/]+)').firstMatch(url);
        return match?.group(1);
      }

      Map<String, dynamic> mergeValid(
        Map<String, dynamic> base,
        Map<String, dynamic> detail,
      ) {
        final merged = Map<String, dynamic>.from(base);

        detail.forEach((key, value) {
          final text = value?.toString().trim() ?? '';
          if (value != null && text.isNotEmpty && text != 'null') {
            merged[key] = value;
          }
        });

        return merged;
      }

      final savedWebReader = clean(book['web_reader']);
      final archiveId = savedWebReader.isNotEmpty
          ? archiveIdFromWebReader(savedWebReader)
          : null;

      String id = clean(book['book_id']);
      if (id.isEmpty) id = clean(book['id']);

      String source = clean(book['source']);
      if (source.isEmpty) source = 'internet_archive';

      // Koleksi lama dari Open Library kadang menyimpan source=open_library,
      // padahal web_reader-nya adalah Internet Archive. Pakai ID Archive agar
      // detail dan reader bisa sama seperti e-book di tab katalog.
      if (archiveId != null && archiveId.isNotEmpty) {
        if (source == 'open_library' ||
            id.startsWith('/works/') ||
            id.startsWith('OL')) {
          source = 'internet_archive';
          id = archiveId;
        }
      }

      Map<String, dynamic> detail = {};

      if (id.isNotEmpty) {
        try {
          final res = await ApiService.getEbookDetail(id, source: source);

          if (res['status'] == 200 && res['data'] is Map) {
            detail = Map<String, dynamic>.from(res['data']);
          }
        } catch (e) {
          debugPrint('Gagal mengambil detail koleksi e-book: $e');
        }
      }

      if (!mounted) return;

      final mergedBook = mergeValid(book, detail);

      // Jangan sampai web_reader dari koleksi ketimpa null dari detail API.
      if (clean(mergedBook['web_reader']).isEmpty &&
          savedWebReader.isNotEmpty) {
        mergedBook['web_reader'] = savedWebReader;
      }

      // Jika detail API mengembalikan ID lain yang kosong/tidak cocok, pakai ID
      // yang dipakai untuk request detail agar progress dan reader tetap nyambung.
      mergedBook['id'] = clean(detail['id']).isNotEmpty ? detail['id'] : id;
      mergedBook['book_id'] = id;
      mergedBook['source'] = clean(detail['source']).isNotEmpty
          ? detail['source']
          : source;
      mergedBook['collection_type'] = 'ebook';

      if (clean(mergedBook['pages']).isEmpty &&
          clean(mergedBook['page_count']).isNotEmpty) {
        mergedBook['pages'] = mergedBook['page_count'];
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(book: mergedBook, isEbook: true),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book, isEbook: false),
      ),
    );
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

    await _loadSavedBookIds();
  }

  Future<void> _loadSavedBookIds() async {
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
        _bookCollections = data;

        _savedBookKeys
          ..clear()
          ..addAll(
            data
                .map((item) {
                  final type = item['collection_type']?.toString() ?? 'catalog';
                  final id = (item['book_id'] ?? item['id'] ?? '').toString();
                  return '$type:$id';
                })
                .where((key) => !key.endsWith(':')),
          );
      });
    }
  }

  Future<void> _toggleBookCollection(
    dynamic book, {
    String collectionType = 'catalog',
  }) async {
    if (_nik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('NIK user tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isCollectionLoading) return;

    final id = _bookId(book);
    if (id.isEmpty) return;

    final key = _collectionKey(book, collectionType);
    final isSaved = _savedBookKeys.contains(key);

    setState(() {
      _isCollectionLoading = true;
    });

    final Map<String, dynamic> res = isSaved
        ? await ApiService.deleteBookCollection(
            nik: _nik,
            bookId: id,
            collectionType: collectionType,
          )
        : await ApiService.addBookCollection(
            nik: _nik,
            book: {
              ...Map<String, dynamic>.from(book),
              'collection_type': collectionType,
            },
            collectionType: collectionType,
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

    await _loadSavedBookIds();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['status'] == 200
              ? isSaved
                    ? 'Buku dihapus dari koleksi'
                    : collectionType == 'ebook'
                    ? 'E-book berhasil disimpan'
                    : 'Buku katalog berhasil disimpan'
              : res['message']?.toString() ?? 'Terjadi kesalahan',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: res['status'] == 200
            ? const Color(0xFF2B5A41)
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onFilterChanged(label),
        selectedColor: const Color(0xFF2B5A41),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1E293B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF2B5A41) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  Widget _buildPremiumBookCard(dynamic book, int index) {
    final titleStr = book['title']?.toString() ?? 'B';
    final initials = titleStr.length > 1
        ? titleStr.substring(0, 2).toUpperCase()
        : titleStr.toUpperCase();

    final isSaved = _savedBookKeys.contains(_collectionKey(book, 'catalog'));
    final coverImage = book['cover_image']?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B5A41).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3ED),
                      borderRadius: BorderRadius.circular(18),
                      image: coverImage != null && coverImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(coverImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: coverImage == null || coverImage.isEmpty
                        ? Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: const Color(
                                  0xFF2B5A41,
                                ).withValues(alpha: 0.16),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _toggleBookCollection(
                        book,
                        collectionType: 'catalog',
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isSaved
                              ? const Color(0xFF2B5A41)
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 19,
                          color: isSaved
                              ? Colors.white
                              : const Color(0xFF2B5A41),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.25,
                      color: Color(0xFF16281F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book['author'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B5A41).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tersedia',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B5A41),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: const Color(0xFF1F4D36),
                expandedHeight: 190,
                floating: true,
                pinned: true,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF123524),
                          Color(0xFF2B5A41),
                          Color(0xFF4C8B64),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: 30,
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 160,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Positioned(
                          right: 32,
                          top: 80,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 42,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 22,
                          right: 110,
                          bottom: 78,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eksplorasi Katalog',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Temukan buku fisik dan e-book favoritmu di sini',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: _openSavedBooksSheet,
                          icon: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.bookmarks_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        if (_bookCollections.isNotEmpty)
                          Positioned(
                            right: 3,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4B740),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _bookCollections.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(62),
                  child: Container(
                    height: 52,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: const Color(0xFF2B5A41).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: const Color(0xFF2B5A41),
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.local_library_rounded, size: 18),
                          text: 'Buku Fisik',
                        ),
                        Tab(
                          icon: Icon(Icons.tablet_mac_rounded, size: 18),
                          text: 'E-Book',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [_buildPhysicalBookView(), const EbookTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalBookView() {
    return Column(
      children: [
        // Floating Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: _buildSearchBarWithDropdown(),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B5A41)),
                )
              : _books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada buku ditemukan.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async => _fetchBooks(reset: true),
                      color: const Color(0xFF2B5A41),
                      child: GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 10,
                          bottom: _isLoadingMore ? 80 : 20,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.56,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          return _buildPremiumBookCard(book, index);
                        },
                      ),
                    ),
                    if (_isLoadingMore)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF2B5A41),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
