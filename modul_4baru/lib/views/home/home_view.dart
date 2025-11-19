import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../restaurant/restaurant_view.dart';
import '../todo/todo_view.dart';
import '../notes/notes_view.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const RestaurantView(),
    const TodoView(),
    const NotesView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        centerTitle: true,
        backgroundColor: _currentIndex == 0 ? Colors.brown[600] : null,
        foregroundColor: _currentIndex == 0 ? Colors.white : null,
        actions: [
          // Theme toggle
          Obx(() => IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _currentIndex == 0 ? Colors.white : null,
            ),
            onPressed: () => themeService.toggleTheme(),
            tooltip: 'Toggle Theme',
          )),

          // User menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.account_circle,
              color: _currentIndex == 0 ? Colors.white : null,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _currentIndex == 0 ? Colors.brown[50] : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _currentIndex == 0 ? Colors.brown[50] : null,
          selectedItemColor: _currentIndex == 0 ? Colors.brown[700] : Get.theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Restaurant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return '🍛 Nasi Padang Online';
      case 1:
        return '📝 Todo List';
      case 2:
        return '📔 Notes';
      default:
        return 'Nasi Padang Online';
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<AuthService>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}