import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';

/// Tela "redefinir senha" (caminho mobile): digita o token do e-mail + nova senha.
class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _carregando = false;
  bool _sucesso = false;
  String? _erro;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthState>().redefinirSenha(
            token: _tokenCtrl.text.trim(),
            novaSenha: _senhaCtrl.text,
          );
      if (mounted) setState(() => _sucesso = true);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _sucesso
                ? Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 56, color: cores.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Senha redefinida!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agora você já pode entrar com a nova senha.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Ir para o login'),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.password_outlined,
                            size: 56, color: cores.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Digite o código/link recebido por e-mail e defina '
                          'uma nova senha.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _tokenCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Código de recuperação',
                              prefixIcon: Icon(Icons.vpn_key_outlined)),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Informe o código do e-mail'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmaCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Confirmar senha',
                              prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) => (v != _senhaCtrl.text)
                              ? 'As senhas não coincidem'
                              : null,
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
                          onPressed: _carregando ? null : _salvar,
                          child: _carregando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : const Text('Salvar nova senha'),
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
