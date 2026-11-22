import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

/// Registro: título arriba; campos y botón abajo (zona del pulgar).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 16),
                    Text('Crea tu cuenta',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Guarda tus favoritos y tus rutas en Bucaramanga',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const Spacer(),
                    AppTextField(
                        controller: _nameCtrl,
                        hint: 'Nombre',
                        icon: Icons.person_outline_rounded),
                    AppTextField(
                        controller: _emailCtrl,
                        hint: 'Correo electrónico',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress),
                    AppTextField(
                        controller: _passCtrl,
                        hint: 'Contraseña (mínimo 6 caracteres)',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true),
                    AppTextField(
                        controller: _confirmCtrl,
                        hint: 'Confirmar contraseña',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        action: TextInputAction.done,
                        onSubmitted: _handleRegister),
                    const SizedBox(height: 4),
                    PrimaryButton(
                        text: 'Crear cuenta',
                        loading: _loading,
                        onTap: _handleRegister),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 14),
                            children: [
                              const TextSpan(text: '¿Ya tienes cuenta?  '),
                              TextSpan(
                                text: 'Inicia sesión',
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

  Future<void> _handleRegister() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm  = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showAppSnack(context, 'Por favor completa todos los campos');
      return;
    }
    if (password != confirm) {
      showAppSnack(context, 'Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      showAppSnack(context, 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);
    final error = await AuthService.register(
        name: name, email: email, password: password);

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        // Cierra el registro para que el StreamBuilder de main.dart
        // muestre la app al detectar la sesión.
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        showAppSnack(context, error);
      }
    }
  }
}
