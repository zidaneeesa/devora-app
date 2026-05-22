import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/catalog_tab.dart';
import 'tabs/loans_tab.dart';
import 'tabs/profile_tab.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(onSeeAllCatalog: () => _changeTab(1)),
      const CatalogTab(),
      const LoansTab(),
      const ProfileTab(),
    ];
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _changeTab(index),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE4F1E8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? const Color(0xFF2B5A41)
                      : const Color(0xFF3F4A45),
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF2B5A41)
                      : const Color(0xFF3F4A45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7FAF8),
      body: _tabs[_currentIndex],

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          onPressed: _openChatbot,
          backgroundColor: const Color(0xFF2B5A41),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          padding: EdgeInsets.zero,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'HOME',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view,
                    label: 'KATALOG',
                  ),

                  const SizedBox(width: 78),

                  _buildNavItem(
                    index: 2,
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'HISTORY',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'PROFIL',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
