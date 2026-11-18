import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../config/app_state.dart';
import 'home_screen.dart';
import 'places_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _index = 0;
  late AnimationController _indicatorCtrl;

  final List<_NavItem> _items = const [
    _NavItem(Icons.map_rounded,    Icons.map_outlined,    'Explorar'),
    _NavItem(Icons.place_rounded,  Icons.place_outlined,  'Lugares'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _indicatorCtrl.forward();
    // Registrar callback para que PlacesScreen pueda cambiar al mapa
    AppState.registerSwitchToMap(() => _onTap(0));
    // Cargar favoritos desde Firestore al iniciar la app
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await AppState.loadFavorites();
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _indicatorCtrl.reset();
    _indicatorCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PlacesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: List.generate(_items.length, (i) => Expanded(child: _navItem(i))),
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final item = _items[i];
    final selected = _index == i;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pill indicator + icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String   label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}