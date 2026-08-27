import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/usuario.dart';
import '../state/auth_state.dart';

/// Tela de criação de conta, com escolha do perfil (Produtor | Técnico de campo).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  PerfilUsuario _perfil = PerfilUsuario.produtor;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    _cidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthState>().registrar(
            email: _emailCtrl.text.trim(),
            senha: _senhaCtrl.text,
            nome: _nomeCtrl.text.trim(),
            perfil: _perfil,
            cidade: _cidadeCtrl.text.trim().isEmpty
                ? null
                : _cidadeCtrl.text.trim(),
          );
      if (mounted) context.go('/');
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
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sou um...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<PerfilUsuario>(
                    segments: const [
                      ButtonSegment(
                        value: PerfilUsuario.produtor,
                        label: Text('Produtor'),
                        icon: Icon(Icons.agriculture_outlined),
                      ),
                      ButtonSegment(
                        value: PerfilUsuario.tecnico,
                        label: Text('Técnico de campo'),
                        icon: Icon(Icons.engineering_outlined),
                      ),
                    ],
                    selected: {_perfil},
                    onSelectionChanged: (s) =>
                        setState(() => _perfil = s.first),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 16),
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
                        labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) =>
                        (v != _senhaCtrl.text) ? 'As senhas não coincidem' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cidadeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Cidade (opcional)',
                        prefixIcon: Icon(Icons.location_city_outlined)),
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
                    onPressed: _carregando ? null : _cadastrar,
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Cadastrar'),
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
