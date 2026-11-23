import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/place_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../config/app_state.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapCtrl = MapController();
  bool _mapReady = false;
  LatLng? _currentPos;
  String _selectedCat = 'Todos';
  List<Marker>   _markers   = [];
  List<Polyline> _polylines = [];
  bool _loadingRoute    = false;
  bool _loadingLocation = true;
  String _priceFilter   = 'Todos';
  double _distFilter    = 50000;
  double _ratingFilter  = 0.0;

  // Buscador
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Modo de ruta
  String _routeMode = 'driving'; // 'driving' | 'walking'
  RouteResult? _lastRouteResult;
  PlaceModel?   _activeRouteDest;


  static final LatLng _bucaCenter = LatLng(7.1193, -73.1227);

  // Máximo de marcadores visibles a la vez (evita llenar el mapa)
  static const int _maxMarkers = 18;
  Timer? _moveDebounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
    AppState.routeRequest.addListener(_onRouteRequest);
    // Filtro en tiempo real por búsqueda
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
      _updateMarkers();
    });
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    AppState.routeRequest.removeListener(_onRouteRequest);
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _currentPos = pos != null
              ? LatLng(pos.latitude, pos.longitude)
              : _bucaCenter;
          _loadingLocation = false;
        });
        _updateMarkers();
      }
    } catch (_) {
      // Timeout o permiso denegado → usar centro de Bucaramanga
      if (mounted) {
        setState(() {
          _currentPos = _bucaCenter;
          _loadingLocation = false;
        });
        _updateMarkers();
      }
    }
  }

  // Escucha cuando PlacesScreen solicita trazar una ruta
  void _onRouteRequest() {
    final place = AppState.routeRequest.value;
    if (place != null) {
      AppState.routeRequest.value = null;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _showRouteTypeSheet(place);
      });
    }
  }

  List<PlaceModel> get _filtered {
    return PlaceModel.allPlaces.where((p) {
      if (_selectedCat != 'Todos' && p.category != _selectedCat) return false;
      if (_priceFilter != 'Todos' && p.priceRange != _priceFilter) return false;
      if (p.rating < _ratingFilter) return false;
      if (_currentPos != null && _distanceTo(p) > _distFilter) return false;
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery) &&
          !p.category.toLowerCase().contains(_searchQuery)) return false;
      return true;
    }).toList();
  }

  double _distanceTo(PlaceModel p) {
    if (_currentPos == null) return 0;
    return Geolocator.distanceBetween(
        _currentPos!.latitude, _currentPos!.longitude, p.lat, p.lng);
  }

  String _fmtDist(PlaceModel p) {
    if (_currentPos == null) return '';
    final d = _distanceTo(p);
    return d < 1000 ? '${d.toInt()} m' : '${(d / 1000).toStringAsFixed(1)} km';
  }

  Marker _placeMarker(PlaceModel p, {bool big = false}) {
    final size = big ? 52.0 : 40.0;
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: size,
      height: size,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showDetail(p),
        child: Icon(Icons.location_on,
            color: big ? AppTheme.accent : _catColor(p.category), size: size),
      ),
    );
  }

  /// Con una ruta activa solo se muestra el destino. Sin ruta, se muestran
  /// los lugares filtrados que están dentro de la pantalla (máx. _maxMarkers),
  /// los más cercanos al centro; al mover o acercar el mapa se recalculan.
  void _updateMarkers() {
    final dest = _activeRouteDest;
    if (_polylines.isNotEmpty && dest != null) {
      setState(() => _markers = [_placeMarker(dest, big: true)]);
      return;
    }
    var list = _filtered;
    if (_mapReady) {
      final bounds = _mapCtrl.camera.visibleBounds;
      final c = _mapCtrl.camera.center;
      list = list.where((p) => bounds.contains(LatLng(p.lat, p.lng))).toList()
        ..sort((a, b) => Geolocator.distanceBetween(c.latitude, c.longitude, a.lat, a.lng)
            .compareTo(Geolocator.distanceBetween(c.latitude, c.longitude, b.lat, b.lng)));
      if (list.length > _maxMarkers) list = list.take(_maxMarkers).toList();
    }
    setState(() => _markers = list.map((p) => _placeMarker(p)).toList());
  }


  // Zoom para mostrar todos los lugares filtrados
  void _fitToFilteredPlaces() {
    final places = _filtered;
    if (places.isEmpty || !_mapReady) return;
    final pts = <LatLng>[
      for (final p in places) LatLng(p.lat, p.lng),
      if (_currentPos != null) _currentPos!,
    ];
    _mapCtrl.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(pts),
      padding: const EdgeInsets.all(60),
      maxZoom: 16,
    ));
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Restaurantes':        return Colors.redAccent;
      case 'Parques':             return Colors.green;
      case 'Centros comerciales': return Colors.blue;
      case 'Cultura':             return Colors.purple;
      default:             return Colors.pinkAccent;
    }
  }

  // Muestra selector de modo antes de trazar
  void _showRouteTypeSheet(PlaceModel dest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
            Text('¿Cómo vas a ir?', style: GoogleFonts.poppins(
              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Selecciona el tipo de ruta hacia ${dest.name}',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _routeModeBtn('🚗', 'En Vehículo', 'driving', dest)),
              const SizedBox(width: 12),
              Expanded(child: _routeModeBtn('🚶', 'A Pie', 'walking', dest)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _routeModeBtn(String icon, String label, String mode, PlaceModel dest) {
    final selected = _routeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _routeMode = mode);
        Navigator.pop(context);
        _traceRoute(dest, mode: mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.surfaceLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _traceRoute(PlaceModel dest, {String mode = 'driving'}) async {
    setState(() { _loadingRoute = true; _polylines.clear(); _lastRouteResult = null; _activeRouteDest = dest; });
    try {
      // Obtener ubicación fresca
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) setState(() => _currentPos = LatLng(pos.latitude, pos.longitude));
      } catch (_) {}
      if (_currentPos == null) {
        setState(() => _loadingRoute = false);
        _snack('No se pudo obtener tu ubicación', err: true);
        return;
      }
      final result = await RouteService.getRoutes(
        _currentPos!.latitude, _currentPos!.longitude, dest.lat, dest.lng,
        mode: mode,
      );
      AppState.routesTraced++;
      FirestoreService.markVisited(placeId: dest.id, placeName: dest.name, category: dest.category);
      FirestoreService.saveRoute(
        placeName: dest.name, placeCategory: dest.category,
        destLat: dest.lat, destLng: dest.lng,
        distanceKm: double.parse((result.distanceMeters / 1000).toStringAsFixed(2)),
      );

      // Ruta con borde blanco y color propio (morado) para que no se
      // confunda con las calles del mapa.
      final mainPts = result.routes[0];
      final newPolylines = <Polyline>[
        Polyline(
          points: mainPts,
          color: Colors.white,
          strokeWidth: 12,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
        Polyline(
          points: mainPts,
          color: AppTheme.route,
          strokeWidth: 7,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ];

      setState(() {
        _polylines = newPolylines;
        _lastRouteResult = result;
        _routeMode = mode;
        _loadingRoute = false;
      });
      _updateMarkers(); // con ruta activa solo queda el destino
      if (mainPts.isNotEmpty && _mapReady) {
        _mapCtrl.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_currentPos!, ...mainPts]),
          padding: const EdgeInsets.all(80),
        ));
      }
    } catch (e) {
      if (mounted) { setState(() => _loadingRoute = false); _snack('No se pudo trazar la ruta', err: true); }
    }
  }

  void _showDetail(PlaceModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlaceDetailSheet(
        place: p,
        distance: _fmtDist(p),
        onFavoriteToggle: () => setState(() {}),
        onRoute: () {
          Navigator.pop(context);
          _showRouteTypeSheet(p);
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        price: _priceFilter, distance: _distFilter, rating: _ratingFilter,
        onApply: (price, dist, rating) {
          setState(() { _priceFilter = price; _distFilter = dist; _ratingFilter = rating; });
          _updateMarkers();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: err ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          // Botones flotantes a la derecha, a la altura del pulgar
          Positioned(
            right: 14,
            bottom: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_polylines.isNotEmpty) ...[
                  _fab(Icons.close_rounded, AppTheme.error,
                      () => _confirmCancelRoute()),
                  const SizedBox(height: 10),
                ],
                _fab(Icons.my_location_rounded, AppTheme.textPrimary, _goToMyLocation),
                const SizedBox(height: 10),
                _fab(Icons.tune_rounded, AppTheme.onAccent, _showFilters, glow: true),
              ],
            ),
          ),
          // Place count badge
          if (!_loadingLocation && _lastRouteResult == null)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 14),
                  child: _countBadge(),
                ),
              ),
            ),
          // Route loader
          if (_loadingRoute) _buildRouteLoader(),
          // Route info card (shown when route is active)
          if (_lastRouteResult != null)
            Positioned(
              top: 0,
              left: 14,
              right: 14,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildRouteInfoCard(),
                ),
              ),
            ),
          // Search bar above chips
          Positioned(
            bottom: 64,
            left: 14,
            right: 14,
            child: _buildSearchBar(),
          ),
          // Category chips at bottom
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _buildCategoryChips(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_loadingLocation) {
      return Container(
        color: AppTheme.background,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _currentPos ?? _bucaCenter,
        initialZoom: 13.5,
        minZoom: 10,
        maxZoom: 18,
        onMapReady: () {
          _mapReady = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateMarkers();
          });
        },
        onPositionChanged: (camera, hasGesture) {
          _moveDebounce?.cancel();
          _moveDebounce = Timer(const Duration(milliseconds: 250), () {
            if (mounted && _polylines.isEmpty) _updateMarkers();
          });
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          // Mosaicos estándar de OpenStreetMap (no requieren llave).
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // Identifica la app ante OpenStreetMap (obligatorio): applicationId.
          userAgentPackageName: 'com.yesidmanrique.explorabga',
          // Se desatura el mapa (casi gris) para que la ruta morada resalte.
          tileBuilder: (context, tileWidget, tile) => ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.55, 0.38, 0.07, 0, 18,
              0.20, 0.73, 0.07, 0, 18,
              0.20, 0.38, 0.42, 0, 18,
              0,    0,    0,    1, 0,
            ]),
            child: tileWidget,
          ),
        ),
        PolylineLayer(polylines: _polylines),
        MarkerLayer(markers: _markers),
        // Punto azul de "mi ubicación" (solo si no es el centro por defecto)
        if (_currentPos != null && _currentPos != _bucaCenter)
          MarkerLayer(markers: [
            Marker(
              point: _currentPos!,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        const SimpleAttributionWidget(
          source: Text('© colaboradores de OpenStreetMap'),
        ),
      ],
    );
  }

  Widget _fab(IconData icon, Color iconColor, VoidCallback onTap, {bool glow = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: glow ? AppTheme.accent : AppTheme.surface.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
            color: glow ? AppTheme.accent.withOpacity(0.45) : Colors.black45,
            blurRadius: 14,
          )],
        ),
        child: Icon(icon, color: glow ? Colors.white : iconColor, size: 22),
      ),
    );
  }

  Widget _countBadge() {
    final count = _filtered.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📍', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            '$count lugares',
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: PlaceModel.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat  = PlaceModel.categories[i];
          final icon = PlaceModel.categoryIcons[cat] ?? '';
          final sel  = cat == _selectedCat;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCat = cat);
              _updateMarkers();
              Future.delayed(const Duration(milliseconds: 200), _fitToFilteredPlaces);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppTheme.accent : AppTheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [BoxShadow(
                  color: sel ? AppTheme.accent.withOpacity(0.5) : Colors.black45,
                  blurRadius: sel ? 14 : 8,
                )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(cat, style: GoogleFonts.poppins(
                    color: sel ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar lugares en Bucaramanga…',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _updateMarkers(); },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    if (_lastRouteResult == null) return const SizedBox.shrink();
    final modeIcon  = _routeMode == 'walking' ? '🚶' : '🚗';
    final modeLabel = _routeMode == 'walking' ? 'A pie' : 'En vehículo';
    final altMode   = _routeMode == 'walking' ? 'driving' : 'walking';
    final altIcon   = _routeMode == 'walking' ? '🚗' : '🚶';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activeRouteDest != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(_activeRouteDest!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(modeIcon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(modeLabel, style: GoogleFonts.poppins(
                    color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(
                    '${_lastRouteResult!.durationLabel}  ·  ${_lastRouteResult!.distanceLabel}',
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botón cambiar modo
          GestureDetector(
            onTap: () {
              if (_activeRouteDest != null) {
                setState(() => _routeMode = altMode);
                _traceRoute(_activeRouteDest!, mode: altMode);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(altIcon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text('Cambiar a ${altMode == "walking" ? "pie" : "vehículo"}',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelRoute() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Cancelar ruta?',
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Se eliminará la ruta trazada del mapa.',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, mantener',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _polylines.clear();
                _lastRouteResult = null;
                _activeRouteDest = null;
              });
              _updateMarkers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sí, cancelar',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLoader() {
    return Positioned(
      bottom: 80, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.accent)),
              const SizedBox(width: 12),
              Text('Trazando ruta…',
                  style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      // Obtener posición fresca del GPS
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentPos = latLng);
      if (_mapReady) _mapCtrl.move(latLng, 16);
    } catch (_) {
      // Si falla, usar la última conocida
      if (_currentPos != null) {
        if (_mapReady) _mapCtrl.move(_currentPos!, 16);
      } else {
        _snack('No se pudo obtener tu ubicación', err: true);
      }
    }
  }
}

// ── Place Detail Sheet ────────────────────────────────────
class _PlaceDetailSheet extends StatefulWidget {
  final PlaceModel place;
  final String     distance;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onRoute;
  const _PlaceDetailSheet({
    required this.place, required this.distance,
    required this.onFavoriteToggle, required this.onRoute,
  });
  @override
  State<_PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<_PlaceDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final isFav = AppState.isFavorite(widget.place.id);
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(widget.place.categoryIcon, style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.place.name, style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(widget.place.category, style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 13)),
                ],
              )),
              GestureDetector(
                onTap: () async {
                  await AppState.toggleFavorite(widget.place.id);
                  setState(() {});
                  widget.onFavoriteToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isFav ? AppTheme.error.withOpacity(0.15) : AppTheme.surfaceLight.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.error : AppTheme.textSecondary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            _chip(Icons.payments_outlined, widget.place.priceRange, AppTheme.accent),
            if (widget.distance.isNotEmpty)
              _chip(Icons.near_me_outlined, widget.distance, AppTheme.textSecondary),
          ]),
          const SizedBox(height: 14),
          Text(widget.place.description, style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 13.5, height: 1.55)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.place.address,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12))),
          ]),
          if (widget.place.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: widget.place.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('#$t', style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: widget.onRoute,
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 18, offset: const Offset(0,7))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Trazar ruta', style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String price; final double distance; final double rating;
  final void Function(String, double, double) onApply;
  const _FilterSheet({required this.price, required this.distance, required this.rating, required this.onApply});
  @override State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _price; late double _dist; late double _rating;
  @override
  void initState() { super.initState(); _price = widget.price; _dist = widget.distance; _rating = widget.rating; }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 38, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text('Filtros', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          Text('Precio', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: PlaceModel.priceFilters.map((p) {
            final sel = p == _price;
            return GestureDetector(
              onTap: () => setState(() => _price = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent : AppTheme.surfaceLight.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p, style: GoogleFonts.poppins(
                    color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList()),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Distancia', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(_dist < 1000 ? '${_dist.toInt()} m' : '${(_dist/1000).toStringAsFixed(0)} km',
                style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          _slider(_dist, 500, 60000, 24, AppTheme.accent, (v) => setState(() => _dist = v)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _price='Todos'; _dist=50000; _rating=0; }),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Limpiar', style: GoogleFonts.poppins(fontSize: 14)),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: () => widget.onApply(_price, _dist, _rating),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,6))],
                ),
                child: Center(child: Text('Aplicar filtros',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5))),
              ),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _slider(double val, double min, double max, int div, Color color, ValueChanged<double> cb) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color, inactiveTrackColor: AppTheme.surfaceLight,
        thumbColor: color, overlayColor: color.withOpacity(0.18), trackHeight: 3,
      ),
      child: Slider(value: val, min: min, max: max, divisions: div, onChanged: cb),
    );
  }
}