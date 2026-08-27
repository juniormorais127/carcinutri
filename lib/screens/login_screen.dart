import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';

/// Tela de entrada na plataforma (email + senha).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthState>().login(
            email: _emailCtrl.text.trim(),
            senha: _senhaCtrl.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e.toString());
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.water_drop_rounded,
                      size: 56, color: cores.primary),
                  const SizedBox(height: 12),
                  Text(
                    'CARCINUTRI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plataforma de carcinicultura',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Informe um email válido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    onFieldSubmitted: (_) => _entrar(),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      style: TextStyle(color: cores.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _carregando ? null : _entrar,
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _carregando ? null : () => context.go('/registro'),
                    child: const Text('Criar uma conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
