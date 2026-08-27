import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';

/// Tela "esqueci minha senha": pede o e-mail e envia o link de recuperação.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _carregando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context
          .read<AuthState>()
          .esqueciSenha(email: _emailCtrl.text.trim());
      if (mounted) setState(() => _enviado = true);
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
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _enviado
                ? Column(
                    children: [
                      Icon(Icons.mark_email_read_outlined,
                          size: 56, color: cores.primary),
                      const SizedBox(height: 16),
                      Text(
                        'E-mail de recuperação enviado',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Se existir uma conta com este e-mail, você receberá '
                        'um link para redefinir sua senha. Confira também a '
                        'caixa de spam.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).maybePop(),
                        child: const Text('Voltar para o login'),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.lock_reset_outlined,
                            size: 56, color: cores.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Informe seu e-mail cadastrado e enviaremos um '
                          'link para redefinir sua senha.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline)),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Informe um email válido'
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
                          onPressed: _carregando ? null : _enviar,
                          child: _carregando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : const Text('Enviar link'),
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
