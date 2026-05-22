import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        if (res['status'] == 200) {
          _notifications = res['data']['data'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(int id, int index) async {
    await ApiService.markNotificationRead(id);
    if (mounted) {
      setState(() {
        _notifications[index]['is_read'] = true;
      });
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsRead();
    if (mounted) {
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
    }
  }

  NotifStyle _getStyle(String type) {
    switch (type) {
      case 'peminjaman_berhasil':
        return NotifStyle(
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF1E40AF), // Blue
          bgColor: const Color(0xFFDBEAFE),
          label: 'Peminjaman',
        );
      case 'pengembalian_berhasil':
        return NotifStyle(
          icon: Icons.assignment_return_rounded,
          color: const Color(0xFF059669), // Emerald
          bgColor: const Color(0xFFD1FAE5),
          label: 'Dikembalikan',
        );
      case 'reminder_pengembalian':
        return NotifStyle(
          icon: Icons.schedule_rounded,
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFFBEB),
          label: 'Pengingat',
        );
      case 'terlambat_pengembalian':
        return NotifStyle(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEA580C),
          bgColor: const Color(0xFFFFF7ED),
          label: 'Terlambat',
        );
      case 'denda_baru':
        return NotifStyle(
          icon: Icons.payments_rounded,
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          label: 'Denda',
        );
      case 'denda_lunas':
        return NotifStyle(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF16A34A),
          bgColor: const Color(0xFFF0FDF4),
          label: 'Lunas',
        );
      case 'perpanjangan_berhasil':
        return NotifStyle(
          icon: Icons.autorenew_rounded,
          color: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          label: 'Perpanjangan',
        );
      default:
        return NotifStyle(
          icon: Icons.notifications_rounded,
          color: const Color(0xFF2B5A41),
          bgColor: const Color(0xFFE4F1E8),
          label: 'Info',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] == false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  color: Color(0xFF2B5A41),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => _fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final style = _getStyle(notif['type'] ?? 'info');
                      final isRead = notif['is_read'] == true;

                      return GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            _markRead(notif['id'], index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : style.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isRead
                                  ? Colors.grey.shade100
                                  : style.color.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: style.color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(style.icon, color: style.color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: style.color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              style.label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: style.color,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: style.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        notif['title'] ?? '',
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 14,
                                          color: isRead
                                              ? Colors.grey.shade700
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['body'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isRead
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        notif['created_at'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
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
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F1E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Color(0xFF2B5A41),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi peminjaman dan\npengembalian buku akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class NotifStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;

  NotifStyle({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
  });
}
