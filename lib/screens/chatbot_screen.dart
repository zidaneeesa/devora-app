import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'book_detail_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  int? _currentConversationId;
  String _currentTitle = 'Percakapan Baru';
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingConversations = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Data Methods ────────────────────────────────────

  Future<void> _loadConversations() async {
    setState(() => _isLoadingConversations = true);
    final res = await ApiService.getConversations();
    if (res['status'] == 200 && mounted) {
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(
          res['data']['data'] ?? [],
        );
        _isLoadingConversations = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _createNewConversation() async {
    final res = await ApiService.createConversation();
    if (res['status'] == 201 && mounted) {
      final conv = res['data']['data'];
      setState(() {
        _currentConversationId = conv['id'];
        _currentTitle = conv['title'];
        _messages = [];
      });
      await _loadConversations();
      if (Navigator.canPop(context)) Navigator.pop(context); // close drawer
    }
  }

  Future<void> _loadMessages(int conversationId) async {
    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    final res = await ApiService.getMessages(conversationId);
    if (res['status'] == 200 && mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(res['data']['data'] ?? []);
        _currentTitle = res['data']['conversation']?['title'] ?? 'Percakapan';
        _isLoading = false;
      });
      _scrollToBottom();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true); // ← FIX: aktifkan loading indicator

    if (_currentConversationId == null) {
      final res = await ApiService.createConversation();
      if (res['status'] == 201) {
        final conv = res['data']['data'];
        setState(() {
          _currentConversationId = conv['id'];
          _currentTitle = conv['title'];
        });
      } else {
        setState(() => _isSending = false);
        return;
      }
    }

    _messageController.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final res = await ApiService.sendChatMessage(_currentConversationId!, text);
    if (res['status'] == 200 && mounted) {
      final data = res['data'];
      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': data['reply'],
          'books': data['books'],
          'created_at': DateTime.now().toIso8601String(),
        });
        _currentTitle = data['conversation']?['title'] ?? _currentTitle;
        _isSending = false;
      });
      _scrollToBottom();
      _loadConversations(); // refresh sidebar
    } else if (mounted) {
      // Tampilkan pesan error yang lebih spesifik
      final errMsg = res['status'] == 503
          ? (res['data']?['message'] ?? 'Layanan AI sedang tidak tersedia. Coba lagi nanti.')
          : res['status'] == 500
          ? 'Koneksi ke server gagal atau timeout. Periksa jaringan kamu.'
          : 'Maaf, terjadi kesalahan. Silakan coba lagi.';
      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': errMsg,
          'created_at': DateTime.now().toIso8601String(),
        });
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _deleteConversation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Percakapan?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Semua pesan dalam percakapan ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteConversation(id);
      if (mounted) {
        if (_currentConversationId == id) {
          setState(() {
            _currentConversationId = null;
            _messages = [];
            _currentTitle = 'Percakapan Baru';
          });
        }
        _loadConversations();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── UI Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _currentConversationId == null && _messages.isEmpty
                ? _buildWelcomeView()
                : _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2B5A41)),
                  )
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2B5A41),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Devora AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _currentTitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          tooltip: 'Chat Baru',
          onPressed: () {
            setState(() {
              _currentConversationId = null;
              _messages = [];
              _currentTitle = 'Percakapan Baru';
            });
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2B5A41),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Devora AI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // New Chat Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentConversationId = null;
                          _messages = [];
                          _currentTitle = 'Percakapan Baru';
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Chat Baru',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2B5A41),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Conversations List
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Riwayat Chat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: _isLoadingConversations
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B5A41),
                      ),
                    )
                  : _conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada percakapan',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final isActive = conv['id'] == _currentConversationId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF2B5A41)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade400,
                            ),
                            title: Text(
                              conv['title'] ?? 'Percakapan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: conv['last_message'] != null
                                ? Text(
                                    conv['last_message'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive
                                          ? Colors.white70
                                          : Colors.grey.shade500,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: isActive
                                    ? Colors.white70
                                    : Colors.red.shade300,
                              ),
                              onPressed: () => _deleteConversation(conv['id']),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _loadMessages(conv['id']);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B5A41).withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF2B5A41),
                size: 56,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Devora AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asisten Pustakawan Cerdas Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            // Suggestion Cards
            _buildSuggestionCard(
              icon: Icons.search_rounded,
              title: 'Cari Buku Spesifik',
              subtitle: '"Carikan buku tentang sejarah Indonesia"',
            ),
            const SizedBox(height: 16),
            _buildSuggestionCard(
              icon: Icons.star_rounded,
              title: 'Minta Rekomendasi',
              subtitle: '"Buku fiksi apa yang paling populer?"',
            ),
            const SizedBox(height: 16),
            _buildSuggestionCard(
              icon: Icons.category_rounded,
              title: 'Jelajah Kategori',
              subtitle: '"Tampilkan buku kategori sains"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        final query = subtitle.replaceAll('"', '');
        _messageController.text = query;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2B5A41), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg, isUser);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2B5A41),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF2B5A41) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isUser ? 24 : 8),
                      bottomRight: Radius.circular(isUser ? 8 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF2B5A41).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _buildFormattedText(msg['message'] ?? '', isUser),
                ),
                // Book recommendations
                if (!isUser &&
                    msg['books'] != null &&
                    (msg['books'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: (msg['books'] as List).length,
                      itemBuilder: (context, i) {
                        final book = (msg['books'] as List)[i];
                        return _buildBookCard(book);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 != 0 && i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      } else {
        String content = parts[i];
        if (i % 2 != 0 && i == parts.length - 1) {
          content = '**$content';
        }
        spans.add(TextSpan(text: content));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF1E293B),
          fontSize: 15,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final coverImage = book['cover_image']?.toString();
    final hasCover =
        coverImage != null &&
        coverImage.trim().isNotEmpty &&
        coverImage != 'null';
    final title = book['title']?.toString() ?? 'Tanpa Judul';
    final initials = title.length > 1
        ? title.substring(0, 2).toUpperCase()
        : title.toUpperCase();

    return GestureDetector(
      onTap: () async {
        final bookId = book['id']?.toString();

        if (bookId == null || bookId.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          );
          return;
        }

        final res = await ApiService.getBookDetail(bookId);

        if (!context.mounted) return;

        if (res['status'] == 200 && res['data'] != null) {
          final detail = Map<String, dynamic>.from(res['data']);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(book: {...book, ...detail}),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          );
        }
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: hasCover
                    ? DecorationImage(
                        image: NetworkImage(coverImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasCover
                  ? Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2B5A41).withValues(alpha: 0.2),
                        ),
                      ),
                    )
                  : null,
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book['author'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2B5A41),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2B5A41),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu pada Devora...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey.shade300
                    : const Color(0xFF2B5A41),
                shape: BoxShape.circle,
                boxShadow: _isSending
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF2B5A41).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
