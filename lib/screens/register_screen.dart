import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/repositories/auth_repository.dart';
import 'package:sikayet_uygulamasi/screens/main_navigation_screen.dart';
import '../data/models/user.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        _formKey.currentState!.save();
        final result = await ref
            .read(authRepositoryProvider)
            .register(name: _name, email: _email, password: _password);
        ref.read(currentUserProvider.notifier).state = result.user;
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'İsim'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen isminizi giriniz';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen email adresinizi girin';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir email adresi girin';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  _email = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre oluşturun';
                  }
                  if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                  return null;
                },
                obscureText: true,
                onSaved: (value) {
                  _password = value!;
                },
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kayıt ol'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                child: const Text('Zaten hesabın var mı? Giriş yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
