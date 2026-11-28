import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../config/app_state.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/place_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _stats = {
    'routesTraced':    0,
    'totalDistanceKm': 0.0,
    'favoritesCount':  0,
  };
  List<Map<String, dynamic>> _routeHistory = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user    = AuthService.currentUser;
    final stats   = await FirestoreService.getStats();
    final history = await FirestoreService.getRouteHistory();
    if (mounted) {
      setState(() {
        if (user != null) {
          AppState.userName  = user.displayName ?? AppState.userName;
          AppState.userEmail = user.email ?? AppState.userEmail;
        }
        _stats        = stats;
        _routeHistory = history;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Información (arriba): quién es el usuario y su resumen ──
            _buildHeader(),
            // ── Opciones (abajo, desplazables): zona del pulgar ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 22),
                  _buildAchievements(),
                  const SizedBox(height: 24),
                  _buildSection('Mi cuenta', [
                    _settingsTile(Icons.edit_rounded, 'Editar perfil',
                        'Nombre, foto y ciudad', onTap: () => _editProfile()),
                    _settingsTile(Icons.lock_outline_rounded, 'Cambiar contraseña',
                        'Actualiza tu contraseña de acceso',
                        onTap: () => _showChangePassword()),
                    _settingsTile(Icons.location_city_rounded, 'Ciudad',
                        AppState.userCity, onTap: () => _showCityPicker()),
                  ]),
                  const SizedBox(height: 18),
                  _buildSection('Exploración', [
                    _settingsTile(Icons.favorite_rounded, 'Mis favoritos',
                        '${AppState.favorites.length} lugares guardados',
                        iconColor: AppTheme.error,
                        onTap: () => _showFavorites()),
                    _settingsTile(Icons.route_rounded, 'Rutas trazadas',
                        '${_stats['routesTraced'] ?? 0} rutas · ${(_stats['totalDistanceKm'] ?? 0.0).toStringAsFixed(1)} km',
                        iconColor: AppTheme.accent,
                        onTap: () => _showRouteHistory()),
                  ]),
                  const SizedBox(height: 18),
                  _buildSection('Preferencias', [
                    _toggleTile(Icons.notifications_outlined, 'Notificaciones',
                        'Alertas de nuevos lugares',
                        AppState.notificationsEnabled,
                        (v) => setState(() => AppState.notificationsEnabled = v)),
                    _toggleTile(Icons.straighten_rounded, 'Distancia en km',
                        'Mostrar distancias en kilómetros',
                        AppState.showDistanceInKm,
                        (v) => setState(() => AppState.showDistanceInKm = v)),
                    _toggleTile(Icons.star_outline_rounded, 'Mostrar calificaciones',
                        'Ver ratings en las tarjetas',
                        AppState.showRatings,
                        (v) => setState(() => AppState.showRatings = v)),
                  ]),
                  const SizedBox(height: 18),
                  _buildSection('Aplicación', [
                    _settingsTile(Icons.info_outline_rounded, 'Acerca de',
                        'Explora BGA · Proyecto de grado UTS', onTap: () => _showAbout()),
                    _settingsTile(Icons.bug_report_outlined, 'Reportar un problema',
                        'Ayúdanos a mejorar la app', onTap: () => _showReportDialog()),
                    _settingsTile(Icons.privacy_tip_outlined, 'Política de privacidad',
                        'Cómo usamos tus datos', onTap: () => _showPrivacyPolicy()),
                  ]),
                  const SizedBox(height: 22),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Encabezado: avatar, nombre, correo y ciudad ───────
  Widget _buildHeader() {
    final hasPhoto = AppState.userPhotoBytes != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent,
                    image: hasPhoto
                        ? DecorationImage(
                            image: MemoryImage(AppState.userPhotoBytes!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: hasPhoto
                      ? null
                      : Center(
                          child: Text(
                            AppState.userName.isNotEmpty
                                ? AppState.userName[0].toUpperCase()
                                : 'E',
                            style: GoogleFonts.poppins(
                                color: AppTheme.onAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppTheme.textPrimary, size: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppState.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                Text(AppState.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 13, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(AppState.userCity,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────
  Widget _buildStatsRow() {
    final routes   = _stats['routesTraced'] ?? 0;
    final favCount = _stats['favoritesCount'] ?? AppState.favorites.length;
    return Row(
      children: [
        _statCard('❤️', '$favCount', 'Favoritos'),
        const SizedBox(width: 10),
        _statCard('🗺️', '$routes', 'Rutas'),
        const SizedBox(width: 10),
        _statCard('🏙️', '${PlaceModel.categories.length - 1}', 'Categorías'),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Achievements ───────────────────────────────────────
  Widget _buildAchievements() {
    final favCount = AppState.favorites.length;
    // Usar stats de Firestore — no la variable local que siempre arranca en 0
    final routes   = (_stats['routesTraced'] ?? 0) as int;

    final List<Map<String, dynamic>> badges = [
      {
        'icon': '🗺️',
        'title': 'Explorador',
        'desc': 'Primer inicio de sesión',
        'unlocked': true,
      },
      {
        'icon': '❤️',
        'title': 'Coleccionista',
        'desc': '5 favoritos',
        'unlocked': favCount >= 5,
      },
      {
        'icon': '🧭',
        'title': 'Navegante',
        'desc': '3 rutas trazadas',
        'unlocked': routes >= 3,
      },
      {
        'icon': '🏆',
        'title': 'Experto Local',
        'desc': '10 rutas trazadas',
        'unlocked': routes >= 10,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏅 Logros',
          style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: badges
              .map((b) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _badge(
                        b['icon'] as String,
                        b['title'] as String,
                        b['desc'] as String,
                        b['unlocked'] as bool,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _badge(String icon, String title, String desc, bool unlocked) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.accent.withOpacity(0.12)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? AppTheme.accent.withOpacity(0.4)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 22,
              color: unlocked ? null : const Color(0x55FFFFFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Settings section ───────────────────────────────────
  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: List.generate(tiles.length, (i) {
              return Column(
                children: [
                  tiles[i],
                  if (i < tiles.length - 1)
                    Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 56),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    String subtitle, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.textSecondary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary, size: 18)
          : null,
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _toggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
        activeTrackColor: AppTheme.accent.withOpacity(0.3),
        inactiveThumbColor: AppTheme.textSecondary,
        inactiveTrackColor: AppTheme.surfaceLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ── Logout ─────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.10),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.error.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.poppins(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────
  String _topCategory() {
    if (AppState.favorites.isEmpty) return 'Sin explorar aún';
    final favPlaces = AppState.places
        .where((p) => AppState.isFavorite(p.id))
        .toList();
    final freq = <String, int>{};
    for (final p in favPlaces) {
      freq[p.category] = (freq[p.category] ?? 0) + 1;
    }
    if (freq.isEmpty) return 'Sin explorar aún';
    return freq.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        onSave: (name, email, city) async {
          AppState.userName = name;
          AppState.userCity = city;
          await FirestoreService.updateProfile(name: name, city: city);
          if (mounted) {
            setState(() {});
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showFavorites() {
    final favs = AppState.places
        .where((p) => AppState.isFavorite(p.id))
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 38, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('❤️ Mis favoritos',
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (favs.isEmpty)
              Expanded(child: Center(child: Text('No tienes favoritos aún',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: favs.length,
                  itemBuilder: (_, i) {
                    final p = favs[i];
                    return ListTile(
                      leading: Text(p.categoryIcon, style: const TextStyle(fontSize: 24)),
                      title: Text(p.name, style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(p.category, style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: GestureDetector(
                        onTap: () { AppState.toggleFavorite(p.id); setState(() {}); Navigator.pop(context); _showFavorites(); },
                        child: const Icon(Icons.favorite_rounded, color: AppTheme.error, size: 20),
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

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 38, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Foto de perfil', style: GoogleFonts.poppins(
              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _photoOption(Icons.camera_alt_rounded, 'Tomar foto',
                'Usa la cámara del dispositivo', () async {
              Navigator.pop(context);
              await _selectImage(ImageSource.camera);
            }),
            const SizedBox(height: 10),
            _photoOption(Icons.photo_library_rounded, 'Elegir de galería',
                'Selecciona una foto existente', () async {
              Navigator.pop(context);
              await _selectImage(ImageSource.gallery);
            }),
            if (AppState.userPhotoBytes != null) ...[
              const SizedBox(height: 10),
              _photoOption(Icons.delete_outline_rounded, 'Eliminar foto',
                  'Volver a mostrar la inicial', () {
                Navigator.pop(context);
                setState(() => AppState.userPhotoBytes = null);
                FirestoreService.savePhoto(null);
              }, isDestructive: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String title, String subtitle,
      VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? AppTheme.error : AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(
              color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
              fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await FirestoreService.savePhoto(base64Encode(bytes));
        if (mounted) setState(() => AppState.userPhotoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo acceder a la foto'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _showCityPicker() {
    const cities = ['Bucaramanga', 'Floridablanca', 'Piedecuesta', 'Girón'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 38, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Selecciona tu ciudad',
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Área metropolitana de Bucaramanga',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ...cities.map((city) {
              final selected = AppState.userCity == city;
              return GestureDetector(
                onTap: () async {
                  setState(() => AppState.userCity = city);
                  await FirestoreService.updateProfile(name: AppState.userName, city: city);
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accent.withOpacity(0.12) : AppTheme.surfaceLight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.accent.withOpacity(0.5) : Colors.white12,
                    ),
                  ),
                  child: Row(children: [
                    Text('📍', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(city, style: GoogleFonts.poppins(
                      color: selected ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    )),
                    const Spacer(),
                    if (selected)
                      const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
                  ]),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showChangePassword() {
    final _newPassCtrl     = TextEditingController();
    final _confirmPassCtrl = TextEditingController();
    bool _obscure1 = true;
    bool _obscure2 = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 38, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text('Cambiar contraseña', style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Mínimo 6 caracteres', style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: _obscure1,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppTheme.textSecondary, size: 19),
                      onPressed: () => setModalState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscure2,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppTheme.textSecondary, size: 19),
                      onPressed: () => setModalState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final newPass  = _newPassCtrl.text.trim();
                    final confirm  = _confirmPassCtrl.text.trim();
                    if (newPass.isEmpty) return;
                    if (newPass != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Las contraseñas no coinciden'),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                      return;
                    }
                    final error = await AuthService.changePassword(newPass);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? '✓ Contraseña actualizada'),
                        backgroundColor: error == null ? AppTheme.success : AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(child: Text('Guardar contraseña',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRouteHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 38, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('🗺️ Historial de rutas',
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tus últimas 20 rutas trazadas',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            if (_routeHistory.isEmpty)
              Expanded(child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧭', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('Aún no has trazado rutas',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                ],
              )))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _routeHistory.length,
                  itemBuilder: (_, i) {
                    final r = _routeHistory[i];
                    final dist = (r['distanceKm'] ?? 0.0).toStringAsFixed(1);
                    final cat  = r['placeCategory'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_rounded, color: AppTheme.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['placeName'] ?? 'Lugar',
                                  style: GoogleFonts.poppins(color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(cat, style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          )),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('$dist km', style: GoogleFonts.poppins(
                                color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ],
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('📍', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('Explora BGA', style: GoogleFonts.poppins(
            color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Text(
                'Aplicación móvil para descubrir y navegar hacia los mejores lugares del área metropolitana de Bucaramanga.',
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Text('Desarrollado por', style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ...[
              ['👨‍💻', 'Sergio Meneses'],
              ['👨‍💻', 'Joan Millán'],
              ['👨‍💻', 'Johann Martínez'],
              ['👨‍💻', 'Yesid Manrique'],
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Text(s[0], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(s[1], style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tecnología en Desarrollo de Sistemas Informáticos', style: GoogleFonts.poppins(
                    color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Semestre 5  ·  Aplicaciones Móviles  ·  UTS', style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 11)),
                  Text('Universidad de Santander — 2026', style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reportar un problema',
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Describe el problema que encontraste:',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: Al trazar una ruta el mapa no se actualiza...',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('¡Gracias! Tu reporte fue enviado.',
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Enviar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.privacy_tip_outlined, color: AppTheme.accent, size: 20),
          const SizedBox(width: 8),
          Text('Política de Privacidad',
              style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _policySection('Datos que recopilamos',
                  'Nombre, correo electrónico y ciudad que el usuario provee al registrarse. Historial de rutas trazadas y lugares favoritos dentro de la app.'),
              _policySection('Cómo usamos los datos',
                  'Los datos se usan exclusivamente para personalizar la experiencia dentro de Explora BGA. No compartimos ni vendemos información a terceros.'),
              _policySection('Almacenamiento',
                  'La información se almacena de forma segura en Firebase Firestore de Google, con acceso restringido únicamente al usuario propietario.'),
              _policySection('Ubicación',
                  'La app accede al GPS del dispositivo solo mientras está en uso, para mostrar tu posición en el mapa y trazar rutas. No almacenamos tu historial de ubicaciones.'),
              _policySection('Tus derechos',
                  'Puedes editar o eliminar tu cuenta en cualquier momento desde la sección de perfil.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Entendido', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _policySection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(
              color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(body, style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.45)),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Cerrar sesión?',
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Tendrás que volver a iniciar sesión para explorar.',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              AppState.clear();
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Salir', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Edit profile sheet ────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final Future<void> Function(String, String, String) onSave;
  const _EditProfileSheet({required this.onSave});
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: AppState.userName);
    _cityCtrl  = TextEditingController(text: AppState.userCity);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 38, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Editar perfil', style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'Nombre', Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _field(_cityCtrl,  'Ciudad',  Icons.location_city_rounded),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => widget.onSave(_nameCtrl.text, AppState.userEmail, _cityCtrl.text),
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(child: Text('Guardar cambios',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      [TextInputType? type]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 19)),
    );
  }
}