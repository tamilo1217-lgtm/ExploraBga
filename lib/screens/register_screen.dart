import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // reuses _MapGridPainter

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0, 0.8, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated background (same painter as login)
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: MapGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: [
                  AppTheme.background.withOpacity(0.30),
                  AppTheme.background.withOpacity(0.70),
                  AppTheme.background.withOpacity(0.92),
                  AppTheme.background,
                ],
              ),
            ),
          ),
          // Glow blob bottom-left
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accentGold.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildHeader(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildCard(),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.45),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppTheme.textPrimary, size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear cuenta',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            Text(
              'Únete a la comunidad exploradora 🗺️',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.90),
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
          _buildField(_nameCtrl,    'Nombre completo',       Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildField(_emailCtrl,   'Correo electrónico',    Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildField(_passCtrl,    'Contraseña',            Icons.lock_outline_rounded,
              isPassword: true,
              obscure: _obscurePass,
              onToggle: () => setState(() => _obscurePass = !_obscurePass)),
          const SizedBox(height: 14),
          _buildField(_confirmCtrl, 'Confirmar contraseña',  Icons.lock_outline_rounded,
              isPassword: true,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 10),
          // Terms note
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: AppTheme.textSecondary),
                children: [
                  const TextSpan(text: 'Al registrarte aceptas los '),
                  TextSpan(
                    text: 'Términos de uso',
                    style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de privacidad',
                    style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildRegisterButton(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿Ya tienes cuenta?  ',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Inicia sesión',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: isPassword && obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        suffixIcon: isPassword && onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.textSecondary,
                  size: 19,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _loading ? null : _handleRegister,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.accentGold]),
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
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Crear cuenta',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm  = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.register(
      name: name, email: email, password: password,
    );

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