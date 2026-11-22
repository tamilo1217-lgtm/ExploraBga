import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

/// Login: la información va arriba y los campos y botones abajo,
/// en la zona que alcanza el pulgar al usar el celular con una mano.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Información (arriba) ──
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.explore_rounded,
                          size: 36, color: AppTheme.onAccent),
                    ),
                    const SizedBox(height: 22),
                    Text('Bienvenido',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Descubre Bucaramanga, la Ciudad de los Parques',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const Spacer(),
                    // ── Acciones (abajo) ──
                    AppTextField(
                      controller: _emailCtrl,
                      hint: 'Correo electrónico',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    AppTextField(
                      controller: _passwordCtrl,
                      hint: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      action: TextInputAction.done,
                      onSubmitted: _handleLogin,
                    ),
                    const SizedBox(height: 4),
                    PrimaryButton(
                        text: 'Iniciar sesión',
                        loading: _loading,
                        onTap: _handleLogin),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text('¿Olvidaste tu contraseña?',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 14),
                            children: [
                              const TextSpan(text: '¿No tienes cuenta?  '),
                              TextSpan(
                                text: 'Regístrate',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      showAppSnack(context, 'Escribe tu correo primero');
      return;
    }
    final error = await AuthService.resetPassword(email);
    if (mounted) {
      showAppSnack(context, error ?? 'Correo de recuperación enviado ✓',
          error: error != null);
    }
  }

  Future<void> _handleLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppSnack(context, 'Por favor completa todos los campos');
      return;
    }

    setState(() => _loading = true);
    final error = await AuthService.login(email: email, password: password);

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        showAppSnack(context, error);
      }
    }
  }
}
