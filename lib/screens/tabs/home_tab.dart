import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_detail_screen.dart';
import '../chatbot_screen.dart';
import 'catalog_tab.dart';
import '../../widgets/notification_bell.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onSeeAllCatalog;

  const HomeTab({super.key, this.onSeeAllCatalog});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _books = [];
  Map<String, dynamic>? _user;
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final bookRes = await ApiService.getBooks();
    final profRes = await ApiService.getProfile();
    final loanRes = await ApiService.getLoans();

    if (mounted) {
      setState(() {
        if (bookRes['status'] == 200) _books = bookRes['data']['data'] ?? [];
        if (profRes['status'] == 200) _user = profRes['data']['user'];
        if (loanRes['status'] == 200) _loans = loanRes['data']['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _showVirtualIdentityCard() {
    final member = _user?['member'] ?? {};
    final memberCode = member['member_code']?.toString() ?? 'SMAN4JEMBER';
    final userName = _user?['name']?.toString() ?? 'Pengguna';
    final memberType = member['type']?.toString().toUpperCase() ?? 'MEMBER';

    final activeLoans = _loans
        .where((l) => l['status'] != 'returned' && l['status'] != 'selesai')
        .length;

    final totalLoans = _loans.length;

    final nisNip = member['nis_nip']?.toString() ?? '-';

    final kelas = member['kelas'] is Map
        ? (member['kelas']['nama_kelas'] ?? member['kelas']['name'] ?? '-')
        : (member['kelas']?.toString() ?? '-');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KARTU IDENTITAS VIRTUAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B5A41),
                          letterSpacing: 1,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: memberCode,
                        version: QrVersions.auto,
                        size: 140,
                        backgroundColor: const Color(0xFFF9FAFB),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      memberType,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B5A41),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'ID Anggota',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  FittedBox(
                    child: Text(
                      memberCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$activeLoans',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B5A41),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PINJAMAN AKTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      Column(
                        children: [
                          Text(
                            '$totalLoans',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B5A41),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TOTAL BUKU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (member['type'] == 'siswa') ...[
                    _identityItem('NIS / NIP', nisNip),
                    const SizedBox(height: 12),
                    _identityItem('KELAS', kelas.toString()),
                  ] else ...[
                    _identityItem('NIP', nisNip),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _identityItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final member = _user?['member'];
    final memberCode = member?['member_code'] ?? 'MEMBER-XXXX';
    final activeLoansCount = _loans
        .where((l) => l['status'] != 'returned')
        .length;
    final userName = _user?['name'] ?? 'Pengguna';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B5A41)),
            )
          : RefreshIndicator(
              onRefresh: () async => _fetchData(),
              color: const Color(0xFF2B5A41),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    // ─── GREEN HEADER BACKGROUND ─────────────────────────
                    Container(
                      height: size.height * 0.32,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B5A41),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 20.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()},',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const NotificationBell(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ─── FLOATING CONTENT ─────────────────────────────
                    Padding(
                      padding: EdgeInsets.only(
                        top: size.height * 0.18,
                        left: 20,
                        right: 20,
                        bottom: 100, // padding for FAB
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Digital Library Card (Floating)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF9FAFB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2B5A41,
                                  ).withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 100,
                                    color: const Color(
                                      0xFF2B5A41,
                                    ).withValues(alpha: 0.03),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'KARTU PERPUSTAKAAN',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 10,
                                                letterSpacing: 1.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'SMAN 4 JEMBER',
                                              style: TextStyle(
                                                color: Color(0xFF1E293B),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Material(
                                          color: const Color(0xFFE8F1EC),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InkWell(
                                            onTap: _showVirtualIdentityCard,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.qr_code_scanner_rounded,
                                                color: Color(0xFF2B5A41),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        memberCode,
                                        style: const TextStyle(
                                          color: Color(0xFF2B5A41),
                                          fontSize: 24,
                                          letterSpacing: 3,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'NAMA ANGGOTA',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                userName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF1E293B),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'PINJAMAN AKTIF',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: activeLoansCount > 0
                                                    ? const Color(0xFFFFF4E5)
                                                    : const Color(0xFFE8F1EC),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$activeLoansCount Buku',
                                                style: TextStyle(
                                                  color: activeLoansCount > 0
                                                      ? const Color(0xFFFF9800)
                                                      : const Color(0xFF2B5A41),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Section Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Katalog Terbaru',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (widget.onSeeAllCatalog != null) {
                                    widget.onSeeAllCatalog!();
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CatalogTab(),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Horizontal Books List
                          _books.isEmpty
                              ? Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Belum ada data buku.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior:
                                        Clip.none, // Allow shadows to show
                                    itemCount: _books.length > 5
                                        ? 5
                                        : _books.length, // Only show 5 terbaru
                                    itemBuilder: (context, index) {
                                      final book = _books[index];
                                      final titleStr =
                                          book['title']?.toString() ?? 'B';
                                      final initials = titleStr.length > 1
                                          ? titleStr
                                                .substring(0, 2)
                                                .toUpperCase()
                                          : titleStr.toUpperCase();

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BookDetailScreen(book: book),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 150,
                                          margin: const EdgeInsets.only(
                                            right: 20,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  width: 150,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    image:
                                                        book['cover_image'] !=
                                                            null
                                                        ? DecorationImage(
                                                            image: NetworkImage(
                                                              book['cover_image'],
                                                            ),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : null,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color:
                                                            const Color(
                                                              0xFF2B5A41,
                                                            ).withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        blurRadius: 20,
                                                        offset: const Offset(
                                                          0,
                                                          10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child:
                                                      book['cover_image'] ==
                                                          null
                                                      ? Center(
                                                          child: Text(
                                                            initials,
                                                            style: TextStyle(
                                                              fontSize: 48,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  const Color(
                                                                    0xFF2B5A41,
                                                                  ).withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                            ),
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                book['title'] ?? 'Tanpa Judul',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  height: 1.2,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                book['author'] ?? '-',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
