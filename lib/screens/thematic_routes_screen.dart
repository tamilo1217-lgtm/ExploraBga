import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_state.dart';
import '../models/place_model.dart';
import '../models/thematic_route.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Sprint 1: lista de rutas temáticas (colección `thematicRoutes` de Firestore).
class ThematicRoutesScreen extends StatefulWidget {
  const ThematicRoutesScreen({Key? key}) : super(key: key);
  @override
  State<ThematicRoutesScreen> createState() => _ThematicRoutesScreenState();
}

class _ThematicRoutesScreenState extends State<ThematicRoutesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ThematicRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AppState.placesVersion.addListener(_onPlacesChanged);
  }

  @override
  void dispose() {
    AppState.placesVersion.removeListener(_onPlacesChanged);
    super.dispose();
  }

  void _onPlacesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final routes = await FirestoreService.getThematicRoutes();
    if (mounted) setState(() { _routes = routes; _loading = false; });
  }

  /// Paradas de la ruta que existen en la lista de lugares (en orden).
  List<PlaceModel> _stopsOf(ThematicRoute r) =>
      r.placeIds.map(AppState.placeById).whereType<PlaceModel>().toList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rutas temáticas',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                  Text('Recorridos sugeridos con varias paradas',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _routes.length,
                        itemBuilder: (_, i) => _routeCard(_routes[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeCard(ThematicRoute r) {
    final stops = _stopsOf(r);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: AppTheme.accent.withOpacity(0.08),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ThematicRouteDetailScreen(route: r, stops: stops),
          )),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(r.icon, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('${stops.length} paradas  ·  ${r.modeIcon} ${r.modeLabel}',
                          style: GoogleFonts.poppins(
                              color: AppTheme.accent, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detalle de una ruta temática: paradas en orden y botón para iniciarla en el mapa.
/// La información va arriba y los controles abajo (uso con una mano).
class ThematicRouteDetailScreen extends StatefulWidget {
  final ThematicRoute route;
  final List<PlaceModel> stops;
  const ThematicRouteDetailScreen({Key? key, required this.route, required this.stops}) : super(key: key);
  @override
  State<ThematicRouteDetailScreen> createState() => _ThematicRouteDetailScreenState();
}

class _ThematicRouteDetailScreenState extends State<ThematicRouteDetailScreen> {
  late String _mode = widget.route.mode;

  void _start() {
    final r = widget.route;
    // Se envía la ruta con el modo que eligió el usuario
    AppState.requestThematicRoute(ThematicRoute(
      id: r.id, name: r.name, description: r.description, icon: r.icon,
      placeIds: widget.stops.map((p) => p.id).toList(), mode: _mode, order: r.order,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(r.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                Text('${r.icon}  ${r.description}',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 18),
                Text('Paradas (${widget.stops.length})',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (var i = 0; i < widget.stops.length; i++) _stopTile(i + 1, widget.stops[i]),
              ],
            ),
          ),
          // Controles abajo, al alcance del pulgar
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: _modeChip('walking', '🚶 A pie')),
                  const SizedBox(width: 10),
                  Expanded(child: _modeChip('driving', '🚗 En vehículo')),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: widget.stops.isEmpty ? null : _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar ruta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String mode, String label) {
    final sel = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: sel ? AppTheme.accent : AppTheme.surfaceLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: sel ? AppTheme.onAccent : AppTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _stopTile(int n, PlaceModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(color: AppTheme.route, shape: BoxShape.circle),
            child: Center(
              child: Text('$n',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.categoryIcon} ${p.name}',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(p.address, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text('🕒 ${p.hours ?? 'Horario por confirmar'}  ·  ${p.priceRange}',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
                if (p.ratingCount > 0)
                  Text('⭐ ${p.ratingLabel}',
                      style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
