import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

// ── Login Screen ─────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _logoScaleAnim;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure   = true;
  bool _loading   = false;

  @override
  void initState() {
    super.initState();

    // infinite background pan
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // staggered entry animations
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
    _logoScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200),
        () => _entryController.forward());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1 · Animated street-grid background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              painter: MapGridPainter(_bgController.value),
              size: Size.infinite,
            ),
          ),
          // 2 · Dark gradient overlay (stronger at bottom so form is readable)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  AppTheme.background.withOpacity(0.25),
                  AppTheme.background.withOpacity(0.65),
                  AppTheme.background.withOpacity(0.90),
                  AppTheme.background,
                ],
              ),
            ),
          ),
          // 3 · Accent glow blob top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accent.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // 4 · Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  // Logo badge + headline
                  ScaleTransition(
                    scale: _logoScaleAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildHeadline(),
                    ),
                  ),
                  const SizedBox(height: 44),
                  // Form card
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildCard(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Headline ───────────────────────────────────────────
  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
          ),
          child: const Text('📍', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 22),
        Text(
          'Explora\nBucaramanga',
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Descubre restaurantes, parques, cines\ny aventuras en la Ciudad Bonita',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Form card ──────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido de vuelta',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inicia sesión para continuar explorando',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Correo electrónico',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _handleForgotPassword(),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.poppins(
                  color: AppTheme.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLoginButton(),
          const SizedBox(height: 22),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && _obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textSecondary,
                  size: 19,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _loading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentGold],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Iniciar sesión',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿No tienes cuenta?  ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text(
            'Regístrate',
            style: GoogleFonts.poppins(
              color: AppTheme.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Escribe tu correo primero');
      return;
    }
    final error = await AuthService.resetPassword(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Correo de recuperación enviado ✓',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: error == null ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
    }
  }

  Future<void> _handleLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.login(email: email, password: password);

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError(error);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }
}

// ── Animated street-grid painter ─────────────────────────
class MapGridPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (looping)
  MapGridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double shift = progress * 80.0; // pixels/cycle

    // ── Background base ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.background,
    );

    final Paint linePaint = Paint()..style = PaintingStyle.stroke;

    // ── Major grid (80px cells) ──
    const double major = 80.0;
    linePaint
      ..color = const Color(0xFF1E3A5F).withOpacity(0.55)
      ..strokeWidth = 1.0;
    _drawGrid(canvas, size, major, shift, linePaint);

    // ── Minor grid (20px cells) ──
    linePaint
      ..color = const Color(0xFF1E3A5F).withOpacity(0.18)
      ..strokeWidth = 0.5;
    _drawGrid(canvas, size, 20.0, shift * 0.25, linePaint);

    // ── Diagonal "avenues" ──
    linePaint
      ..color = AppTheme.accent.withOpacity(0.06)
      ..strokeWidth = 1.5;
    final double diagShift = (shift * 0.6) % 160.0;
    for (double i = -size.height + diagShift; i < size.width + size.height; i += 160) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
    }

    // ── Intersection dots ──
    final Paint dotPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    for (double y = -(major) + (shift % major); y < size.height + major; y += major) {
      for (double x = -(major) + (shift % major); x < size.width + major; x += major) {
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }

    // ── Highlight one random block with a faint rect ──
    final Paint blockPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final double bx = (shift * 2.3) % size.width;
    final double by = (shift * 1.7) % size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, major, major),
        const Radius.circular(4),
      ),
      blockPaint,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double step, double offset, Paint paint) {
    final double off = offset % step;
    for (double y = -step + off; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = -step + off; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(MapGridPainter old) => old.progress != progress;
}