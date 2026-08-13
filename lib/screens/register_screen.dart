import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/screens/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import '../core/app_colors.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _phoneNumber = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        _formKey.currentState!.save();
        final result = await ref
            .read(authRepositoryProvider)
            .register(
              name: _name,
              email: _email,
              password: _password,
              phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : null,
            );

        ref.read(currentUserProvider.notifier).state = result.user;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(
                  color: AppColors.rejectedFg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.rejectedBg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // MARKA HEADER I
          const AuthHeader(
            title: 'Hesap Oluştur',
            subtitle: 'Belediye hizmetlerine hemen erişin',
            icon: Icons.person_add_alt_1_outlined,
          ),

          // KAYDIRILABİLİR FORM ALANI
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAuthField(
                      label: 'İSİM SOYİSİM',
                      hint: 'Adınız Soyadınız',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      colorScheme: colorScheme,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Lütfen isminizi giriniz';
                        return null;
                      },
                      onSaved: (value) => _name = value!.trim(),
                    ),
                    const SizedBox(height: 20),

                    _buildAuthField(
                      label: 'E-POSTA',
                      hint: 'ornek@eposta.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      colorScheme: colorScheme,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Lütfen email adresinizi girin';
                        if (!value.contains('@'))
                          return 'Geçerli bir email adresi girin';
                        return null;
                      },
                      onSaved: (value) => _email = value!.trim(),
                    ),
                    const SizedBox(height: 20),

                    _buildAuthField(
                      label: 'TELEFON (OPSİYONEL)',
                      hint: '05XX XXX XX XX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      colorScheme: colorScheme,
                      onSaved: (value) => _phoneNumber = value!.trim(),
                    ),
                    const SizedBox(height: 20),

                    _buildAuthField(
                      label: 'ŞİFRE',
                      hint: 'En az 6 karakter',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      colorScheme: colorScheme,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitForm(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.outline,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Şifre oluşturun';
                        if (value.length < 6)
                          return 'Şifre en az 6 karakter olmalı';
                        return null;
                      },
                      onSaved: (value) => _password = value!,
                    ),
                    const SizedBox(height: 32),

                    // ANA KAYIT BUTONU
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // VEYA AYIRICI
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'veya',
                            style: TextStyle(color: colorScheme.outline),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: colorScheme.outlineVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // GİRİŞ YAP YÖNLENDİRMESİ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zaten hesabın var mı?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Giriş alanı tasarımı
Widget _buildAuthField({
  required String label,
  required String hint,
  required IconData icon,
  required ColorScheme colorScheme,
  bool obscureText = false,
  Widget? suffixIcon,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  void Function(String)? onFieldSubmitted,
  String? Function(String?)? validator,
  void Function(String?)? onSaved,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colorScheme.outline,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        onSaved: onSaved,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(icon, color: colorScheme.outline),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ],
  );
}
