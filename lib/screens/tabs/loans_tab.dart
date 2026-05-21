import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../book_reader_screen.dart';
import '../../widgets/notification_bell.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab> with SingleTickerProviderStateMixin {
  String _filter = 'semua';
  List<dynamic> _loans = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDate(String? date) {
    if (date == null) return '-';
    final d = DateTime.tryParse(date);
    if (d == null) return '-';
    return "${d.day}/${d.month}/${d.year}";
  }

  void _fetchLoans() async {
    final loanRes = await ApiService.getLoans();
    final ebookRes = await ApiService.getAllReadingProgress();

    List<dynamic> combined = [];

    if (loanRes['status'] == 200) {
      combined.addAll(loanRes['data']['data'] ?? []);
    }

    for (var ebook in ebookRes) {
      final detail = await ApiService.getEbookDetail(ebook['ebook_id']);

      int current = ebook['current_page'] ?? 0;
      int total = ebook['total_page'] ?? 0;

      String status = (total > 0 && current >= total) ? 'selesai' : 'aktif';

      combined.add({
        'type': 'ebook',
        'status': status,
        'book': {
          'title': detail['data']['title'],
          'cover_image': detail['data']['cover_image'],
          'author': '-',
        },
        'ebook_id': ebook['ebook_id'],
        'current_page': current,
        'total_page': total,
        'pdf_link': detail['data']['pdf_link'],
        'updated_at': ebook['updated_at'],
      });
    }

    setState(() {
      _loans = combined;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredLoans = _loans.where((l) {
      if (_filter == 'ebook') return l['type'] == 'ebook';
      if (_filter == 'fisik') return l['type'] != 'ebook';
      return true;
    }).toList();

    final activeLoans = filteredLoans.where((l) => l['status'] != 'selesai').toList();
    final pastLoans = filteredLoans.where((l) => l['status'] == 'selesai').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Column(
        children: [
          // ─── GREEN HEADER BACKGROUND ─────────────────────────
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF2B5A41),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas\nPinjaman',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      NotificationBell(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // TAB BAR (Aktif / Selesai)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                        ],
                      ),
                      labelColor: const Color(0xFF2B5A41),
                      unselectedLabelColor: Colors.white70,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Sedang Aktif'),
                        Tab(text: 'Selesai'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── FILTERS ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              children: [
                _buildFilterButton('Semua', 'semua'),
                const SizedBox(width: 8),
                _buildFilterButton('E-Book', 'ebook'),
                const SizedBox(width: 8),
                _buildFilterButton('Buku Fisik', 'fisik'),
              ],
            ),
          ),

          // ─── CONTENT LIST ─────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5A41)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoanList(activeLoans, true),
                      _buildLoanList(pastLoans, false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B5A41) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B5A41) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanList(List<dynamic> loans, bool isActive) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada riwayat.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _fetchLoans(),
      color: const Color(0xFF2B5A41),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          final book = loan['book'] ?? {};
          final isEbook = loan['type'] == 'ebook';

          DateTime? dueDate = loan['due_date'] != null ? DateTime.tryParse(loan['due_date']) : null;
          DateTime today = DateTime.now();

          String dateText;
          if (isEbook) {
            dateText = isActive ? "Dibaca: ${formatDate(loan['updated_at'])}" : "Selesai: ${formatDate(loan['updated_at'])}";
          } else {
            if (isActive) {
              if (dueDate != null && today.isAfter(dueDate)) {
                dateText = "Terlambat (${loan['due_date']})";
              } else {
                dateText = "Batas: ${loan['due_date']}";
              }
            } else {
              dateText = "Kembali: ${loan['return_date']}";
            }
          }

          final initials = (book['title']?.toString() ?? 'B').substring(0, 1).toUpperCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2B5A41).withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    Container(
                      width: 80,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F5),
                        borderRadius: BorderRadius.circular(16),
                        image: book['cover_image'] != null
                            ? DecorationImage(image: NetworkImage(book['cover_image']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: book['cover_image'] == null
                          ? Center(child: Text(initials, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF2B5A41).withValues(alpha: 0.2))))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEbook ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEbook ? "E-BOOK" : "FISIK",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isEbook ? Colors.blue.shade700 : Colors.orange.shade800),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFE8F1EC) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'AKTIF' : 'SELESAI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? const Color(0xFF2B5A41) : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            book['title'] ?? 'Tanpa Judul',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book['author'] ?? '-',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          if (isEbook) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Hal ${loan['current_page']} / ${loan['total_page']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                Text("${((loan['current_page'] ?? 0) / (loan['total_page'] == 0 ? 1 : loan['total_page']) * 100).toInt()}%", style: const TextStyle(fontSize: 11, color: Color(0xFF2B5A41), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (loan['total_page'] == 0) ? 0 : loan['current_page'] / loan['total_page'],
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE8F1EC),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B5A41)),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(dateText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (isActive && isEbook) ...[
                  const SizedBox(height: 20),
                  if (isEbook)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookReaderScreen(
                              url: loan['pdf_link'],
                              title: loan['book']['title'] ?? 'E-Book',
                              ebookId: loan['ebook_id'].toString(),
                              initialPage: (loan['current_page'] ?? 1),
                            ),
                          ),
                        ).then((_) => _fetchLoans());
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text("Lanjut Membaca", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5A41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
