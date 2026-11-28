import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_state.dart';
import '../models/place_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

/// Abre la hoja de reseñas de un lugar (Sprint 2).
void showReviewsSheet(BuildContext context, PlaceModel place) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ReviewsSheet(place: place),
  );
}

/// Reseñas de un lugar: lista en tiempo real arriba y el formulario del usuario
/// abajo (zona del pulgar). Cada usuario tiene una sola reseña por lugar.
class ReviewsSheet extends StatefulWidget {
  final PlaceModel place;
  const ReviewsSheet({Key? key, required this.place}) : super(key: key);
  @override
  State<ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends State<ReviewsSheet> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  bool _loadedMine = false; // ya se cargó la reseña propia en el formulario
  bool _hasMine = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      showAppSnack(context, 'Elige de 1 a 5 estrellas');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.saveReview(
        placeId: widget.place.id,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        userName: AppState.userName,
      );
      await AppState.refreshPlaceRating(widget.place.id);
      if (mounted) {
        FocusScope.of(context).unfocus();
        showAppSnack(context, _hasMine ? 'Reseña actualizada' : 'Reseña publicada', error: false);
        setState(() => _hasMine = true);
      }
    } catch (e) {
      print('=== RESEÑA error: $e');
      if (mounted) showAppSnack(context, 'No se pudo guardar la reseña');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await FirestoreService.deleteReview(widget.place.id);
      await AppState.refreshPlaceRating(widget.place.id);
      if (mounted) {
        _commentCtrl.clear();
        setState(() { _rating = 0; _hasMine = false; });
        showAppSnack(context, 'Reseña eliminada', error: false);
      }
    } catch (e) {
      print('=== RESEÑA error: $e');
      if (mounted) showAppSnack(context, 'No se pudo eliminar la reseña');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUserId;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.reviewsStream(widget.place.id),
        builder: (context, snap) {
          final reviews = snap.data ?? [];
          // La primera vez que llegan los datos se llena el formulario con la reseña propia
          if (snap.hasData && !_loadedMine) {
            _loadedMine = true;
            final mine = reviews.where((r) => r['id'] == uid).toList();
            if (mine.isNotEmpty) {
              _hasMine = true;
              _rating = (mine.first['rating'] as num?)?.toInt() ?? 0;
              _commentCtrl.text = mine.first['comment'] as String? ?? '';
            }
          }
          final count = reviews.length;
          final avg = count == 0
              ? 0.0
              : reviews.map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / count;

          return Column(
            children: [
              // ── Información arriba ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 38, height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Text('Reseñas', style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w700)),
                    Text(widget.place.name, style: GoogleFonts.poppins(color: AppTheme.accent, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(count == 0
                            ? 'Aún no tiene reseñas. ¡Sé el primero!'
                            : '⭐ ${avg.toStringAsFixed(1)} de 5  ·  $count ${count == 1 ? 'reseña' : 'reseñas'}',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: snap.hasError
                    ? Center(child: Text('No se pudieron cargar las reseñas',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)))
                    : !snap.hasData
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            itemCount: reviews.length,
                            itemBuilder: (_, i) => _reviewTile(reviews[i], reviews[i]['id'] == uid),
                          ),
              ),
              // ── Formulario abajo (pulgar) ───────────────────
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppTheme.accent, size: 36),
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 2,
                      maxLength: 300,
                      style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Cuéntale a otros cómo te fue (opcional)',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (_hasMine) ...[
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _saving ? null : _delete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: PrimaryButton(
                          text: _hasMine ? 'Actualizar mi reseña' : 'Publicar reseña',
                          loading: _saving,
                          onTap: _save,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r, bool mine) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final comment = (r['comment'] as String?) ?? '';
    final ts = r['updatedAt'];
    final date = ts is Timestamp ? ts.toDate() : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? AppTheme.accent.withOpacity(0.08) : AppTheme.surfaceLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: mine ? Border.all(color: AppTheme.accent.withOpacity(0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(mine ? '${r['userName'] ?? 'Tú'} (tú)' : (r['userName'] as String? ?? 'Usuario'),
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text('★' * rating + '☆' * (5 - rating),
                style: const TextStyle(color: AppTheme.accent, fontSize: 14)),
          ]),
          if (date != null)
            Text('${date.day}/${date.month}/${date.year}',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 10.5)),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(comment, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
