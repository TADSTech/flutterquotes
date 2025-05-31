import 'package:flutter/material.dart';
import 'package:flutterquotes/cached_screen.dart';
import 'package:flutterquotes/category_screen.dart';
import 'package:flutterquotes/favorites_screen.dart';
import 'package:flutterquotes/home_screen.dart';
import 'package:flutterquotes/services/notification_service.dart';
import 'package:flutterquotes/settings_screen.dart';
import 'package:flutterquotes/theme_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => const [
        HomeScreen(),
        CachedQuotesScreen(),
        FavoritesScreen(),
        CategoryScreen(),
        SettingsScreen(),
      ];

  // Define a breakpoint for switching layouts
  static const double _kTabletBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= _kTabletBreakpoint;
    return isLargeScreen
        ? _buildLargeScreenLayout()
        : _buildSmallScreenLayout();
  }

  // Layout for smaller screens (mobile)
  Widget _buildSmallScreenLayout() {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // Layout for larger screens (tablet/desktop)
  Widget _buildLargeScreenLayout() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail for larger screens
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: themeProvider.navigationBarBackground,
            selectedIconTheme:
                IconThemeData(color: themeProvider.navigationBarSelected),
            unselectedIconTheme:
                IconThemeData(color: themeProvider.navigationBarUnselected),
            selectedLabelTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeProvider.navigationBarSelected,
            ),
            unselectedLabelTextStyle: TextStyle(
              fontSize: 12,
              color: themeProvider.navigationBarUnselected,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cached_outlined),
                selectedIcon: Icon(Icons.cached),
                label: Text('Cache'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: Text('Favorites'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          // A vertical divider for visual separation (optional)
          VerticalDivider(
              thickness: 1, width: 1, color: Colors.grey.withOpacity(0.3)),
          // Main content takes the rest of the space
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: themeProvider.navigationBarBackground,
        selectedItemColor: themeProvider.navigationBarSelected,
        unselectedItemColor: themeProvider.navigationBarUnselected,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: themeProvider.navigationBarSelected,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          color: themeProvider.navigationBarUnselected,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: _navigationItems,
      ),
    );
  }

  List<BottomNavigationBarItem> get _navigationItems => const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cached_outlined),
          activeIcon: Icon(Icons.cached),
          label: 'Cache',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];
}
