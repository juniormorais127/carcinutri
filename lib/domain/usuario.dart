/// Perfil (papel) do usuário na plataforma.
enum PerfilUsuario {
  produtor,
  tecnico;

  String get rotulo => this == produtor ? 'Produtor' : 'Técnico de campo';

  static PerfilUsuario daString(String? valor) {
    switch (valor) {
      case 'tecnico':
        return PerfilUsuario.tecnico;
      case 'produtor':
      default:
        return PerfilUsuario.produtor;
    }
  }
}

/// Usuário logado (dados retornados pelo backend em /auth/me e /auth/login).
class UsuarioLogado {
  final String id;
  final String email;
  final String nome;
  final String? telefone;
  final String? cidade;
  final String? regiao;
  final PerfilUsuario perfil;

  const UsuarioLogado({
    required this.id,
    required this.email,
    required this.nome,
    this.telefone,
    this.cidade,
    this.regiao,
    required this.perfil,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'cidade': cidade,
        'regiao': regiao,
        'role': perfil.name,
      };

  factory UsuarioLogado.fromJson(Map<String, dynamic> j) => UsuarioLogado(
        id: j['id'] as String,
        email: j['email'] as String,
        nome: j['nome'] as String,
        telefone: j['telefone'] as String?,
        cidade: j['cidade'] as String?,
        regiao: j['regiao'] as String?,
        perfil: PerfilUsuario.daString(j['role'] as String?),
      );
}
