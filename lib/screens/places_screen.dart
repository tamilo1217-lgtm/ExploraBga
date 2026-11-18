import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../models/place_model.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../config/app_state.dart';
import '../services/firestore_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({Key? key}) : super(key: key);
  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  LatLng? _pos;
  String _cat          = 'Todos';
  String _priceFilter  = 'Todos';
  double _distFilter   = 50000;
  double _ratingFilter = 0.0;
  bool   _favOnly      = false;
  String _sortBy       = 'distancia'; // distancia | calificacion | nombre

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (mounted && pos != null) {
      setState(() => _pos = LatLng(pos.latitude, pos.longitude));
    }
  }

  List<PlaceModel> get _filtered {
    var list = PlaceModel.allPlaces.where((p) {
      if (_cat != 'Todos' && p.category != _cat) return false;
      if (_priceFilter != 'Todos' && p.priceRange != _priceFilter) return false;
      if (p.rating < _ratingFilter) return false;
      if (_favOnly && !AppState.isFavorite(p.id)) return false;
      if (_pos != null && _distanceTo(p) > _distFilter) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'calificacion':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'nombre':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      default: // distancia
        if (_pos != null) list.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    }
    return list;
  }

  double _distanceTo(PlaceModel p) {
    if (_pos == null) return 0;
    return Geolocator.distanceBetween(_pos!.latitude, _pos!.longitude, p.lat, p.lng);
  }

  String _fmtDist(PlaceModel p) {
    if (_pos == null) return '';
    final d = _distanceTo(p);
    return d < 1000 ? '${d.toInt()} m' : '${(d / 1000).toStringAsFixed(1)} km';
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlacesFilterSheet(
        price: _priceFilter, distance: _distFilter,
        rating: _ratingFilter, sortBy: _sortBy,
        onApply: (price, dist, rating, sort) {
          setState(() {
            _priceFilter  = price;
            _distFilter   = dist;
            _ratingFilter = rating;
            _sortBy       = sort;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final places = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(places.length),
            _buildCategoryRow(),
            Expanded(
              child: places.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: places.length,
                      itemBuilder: (_, i) => _placeCard(places[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lugares',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                Text('$count resultados en Bucaramanga',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          // Favoritos toggle
          GestureDetector(
            onTap: () => setState(() => _favOnly = !_favOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _favOnly
                    ? AppTheme.error.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: _favOnly
                        ? AppTheme.error.withOpacity(0.5)
                        : Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _favOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _favOnly ? AppTheme.error : AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text('Favoritos',
                      style: GoogleFonts.poppins(
                        color: _favOnly ? AppTheme.error : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: _favOnly ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showFilters,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppTheme.accent.withOpacity(0.45), blurRadius: 12)],
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PlaceModel.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat  = PlaceModel.categories[i];
          final icon = PlaceModel.categoryIcons[cat] ?? '';
          final sel  = cat == _cat;
          return GestureDetector(
            onTap: () => setState(() => _cat = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: sel ? null : Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(cat,
                      style: GoogleFonts.poppins(
                        color: sel ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
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

  Widget _placeCard(PlaceModel p) {
    final isFav = AppState.isFavorite(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          onTap: () => _openDetail(p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(p.categoryIcon,
                      style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(p.category,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accentGold, size: 12),
                        const SizedBox(width: 3),
                        Text(p.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                color: AppTheme.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(p.priceRange,
                            style: GoogleFonts.poppins(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        if (_fmtDist(p).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(_fmtDist(p),
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ]),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await AppState.toggleFavorite(p.id);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isFav
                          ? AppTheme.error.withOpacity(0.12)
                          : AppTheme.surfaceLight.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.error : AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(PlaceModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuickDetailSheet(place: p, distance: _fmtDist(p),
          onToggleFav: () => setState(() {})),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_favOnly ? '🤍' : '🔍', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            _favOnly ? 'Sin favoritos aún' : 'Sin resultados',
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _favOnly
                ? 'Guarda lugares con ❤️ para verlos aquí'
                : 'Prueba cambiando los filtros',
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          if (!_favOnly) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() {
                _cat = 'Todos'; _priceFilter = 'Todos';
                _distFilter = 50000; _ratingFilter = 0;
              }),
              child: Text('Limpiar filtros',
                  style: GoogleFonts.poppins(color: AppTheme.accent)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick detail from places list ────────────────────────
class _QuickDetailSheet extends StatefulWidget {
  final PlaceModel place;
  final String distance;
  final VoidCallback onToggleFav;
  const _QuickDetailSheet({required this.place, required this.distance, required this.onToggleFav});
  @override State<_QuickDetailSheet> createState() => _QuickDetailSheetState();
}

class _QuickDetailSheetState extends State<_QuickDetailSheet> {
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(widget.place.categoryIcon, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.place.name, style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              Text(widget.place.category, style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 13)),
            ])),
            GestureDetector(
              onTap: () async { await AppState.toggleFavorite(widget.place.id); setState(() {}); widget.onToggleFav(); },
              child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppTheme.error : AppTheme.textSecondary, size: 22),
            ),
          ]),
          const SizedBox(height: 12),
          Text(widget.place.description, style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 13.5, height: 1.55)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.place.address,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.star_rounded, widget.place.rating.toStringAsFixed(1), 'Rating', AppTheme.accentGold),
                _divider(),
                _stat(Icons.payments_outlined, widget.place.priceRange, 'Precio', AppTheme.accent),
                _divider(),
                _stat(Icons.near_me_outlined, widget.distance.isEmpty ? '—' : widget.distance, 'Distancia', AppTheme.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              AppState.requestRoute(widget.place);
            },
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                borderRadius: BorderRadius.circular(27),
                boxShadow: [BoxShadow(
                  color: AppTheme.accent.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Trazar ruta', style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.poppins(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 10.5)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.white12);
}

// ── Places Filter Sheet ───────────────────────────────────
class _PlacesFilterSheet extends StatefulWidget {
  final String price; final double distance; final double rating; final String sortBy;
  final void Function(String, double, double, String) onApply;
  const _PlacesFilterSheet({
    required this.price, required this.distance,
    required this.rating, required this.sortBy, required this.onApply,
  });
  @override State<_PlacesFilterSheet> createState() => _PlacesFilterSheetState();
}

class _PlacesFilterSheetState extends State<_PlacesFilterSheet> {
  late String _price; late double _dist; late double _rating; late String _sort;
  @override
  void initState() {
    super.initState();
    _price = widget.price; _dist = widget.distance;
    _rating = widget.rating; _sort = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
          Text('Filtros y orden', style: GoogleFonts.poppins(
              color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _label('Precio'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['Todos', '\$', '\$\$', '\$\$\$', 'Gratis'].map((p) =>
            _chip(p, p == _price, () => setState(() => _price = p))).toList()),
          const SizedBox(height: 20),
          _label('Ordenar por'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _chip('Distancia', _sort == 'distancia', () => setState(() => _sort = 'distancia')),
            _chip('Calificación', _sort == 'calificacion', () => setState(() => _sort = 'calificacion')),
            _chip('Nombre A-Z', _sort == 'nombre', () => setState(() => _sort = 'nombre')),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _label('Distancia máxima'),
            Text(_dist < 1000 ? '${_dist.toInt()} m' : '${(_dist/1000).toStringAsFixed(0)} km',
                style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          _slider(_dist, 500, AppTheme.accent, (v) => setState(() => _dist = v)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _label('Calificación mínima'),
            Text(_rating == 0 ? 'Todas' : '${_rating.toStringAsFixed(1)}+',
                style: GoogleFonts.poppins(color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          _slider(_rating, 0, AppTheme.accentGold, (v) => setState(() => _rating = v), max: 5, div: 10),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _price='Todos'; _dist=50000; _rating=0; _sort='distancia'; }),
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
              onTap: () => widget.onApply(_price, _dist, _rating, _sort),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentGold]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(child: Text('Aplicar',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5))),
              ),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.poppins(
      color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.accent : AppTheme.surfaceLight.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.poppins(
            color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 13,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _slider(double val, double min, Color color, ValueChanged<double> cb,
      {double max = 60000, int div = 24}) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color, inactiveTrackColor: AppTheme.surfaceLight,
        thumbColor: color, overlayColor: color.withOpacity(0.18), trackHeight: 3,
      ),
      child: Slider(value: val, min: min, max: max, divisions: div, onChanged: cb),
    );
  }
}