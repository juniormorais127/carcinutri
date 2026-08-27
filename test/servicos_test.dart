import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:carcini_calc/db/repositories.dart';
import 'package:carcini_calc/domain/servico.dart';

void main() {
  group('Modelos do Marketplace de Serviços', () {
    test('SolicitacaoServico toJson e fromJson com sincronização offline', () {
      final now = DateTime(2026, 8, 27, 10, 30);
      final s = SolicitacaoServico(
        id: '123e4567-e89b-12d3-a456-426614174000',
        produtorId: '987fcdeb-51a2-43d7-9876-543210987654',
        produtorNome: 'Produtor Teste',
        titulo: 'Manutenção de Bombas',
        descricao: 'Reparo em bomba do setor 1',
        categoria: 'Manutenção',
        cidade: 'Aracati',
        valorEstimado: 1200.50,
        status: 'aberto',
        criadoEm: now,
        sincronizado: false,
      );

      final json = s.toJson();
      expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(json['valor_estimado'], 1200.50);
      expect(json['sincronizado'], false);

      final reconstruido = SolicitacaoServico.fromJson(json);
      expect(reconstruido.id, s.id);
      expect(reconstruido.titulo, s.titulo);
      expect(reconstruido.valorEstimado, 1200.50);
      expect(reconstruido.sincronizado, false);

      final sincronizado = reconstruido.marcadoSincronizado();
      expect(sincronizado.sincronizado, true);
    });

    test('PropostaServico toJson e fromJson', () {
      final now = DateTime(2026, 8, 27, 11, 00);
      final p = PropostaServico(
        id: 'p-1',
        servicoId: 's-1',
        tecnicoId: 't-1',
        tecnicoNome: 'Técnico Especialista',
        valor: 1100.00,
        mensagem: 'Tenho disponibilidade imediata',
        status: 'pendente',
        criadoEm: now,
      );

      final json = p.toJson();
      final p2 = PropostaServico.fromJson(json);
      expect(p2.id, 'p-1');
      expect(p2.valor, 1100.00);
      expect(p2.tecnicoNome, 'Técnico Especialista');
      expect(p2.status, 'pendente');
    });

    test('ContratoServico toJson e fromJson', () {
      final now = DateTime(2026, 8, 27, 11, 30);
      final c = ContratoServico(
        id: 'c-1',
        servicoId: 's-1',
        servicoTitulo: 'Manutenção de Bombas',
        produtorId: 'p-1',
        produtorNome: 'Produtor Teste',
        tecnicoId: 't-1',
        tecnicoNome: 'Técnico Especialista',
        valorAcordado: 1100.00,
        pagamento: 'pago',
        execucao: 'em_andamento',
        comunicacaoLiberada: true,
        criadoEm: now,
      );

      final json = c.toJson();
      final c2 = ContratoServico.fromJson(json);
      expect(c2.id, 'c-1');
      expect(c2.valorAcordado, 1100.00);
      expect(c2.pagamento, 'pago');
      expect(c2.execucao, 'em_andamento');
      expect(c2.comunicacaoLiberada, true);
    });

    test('MensagemServico toJson e fromJson', () {
      final now = DateTime(2026, 8, 27, 12, 00);
      final m = MensagemServico(
        id: 'm-1',
        contratoId: 'c-1',
        remetenteId: 'p-1',
        remetenteNome: 'Produtor Teste',
        texto: 'Pagamento confirmado em custódia!',
        criadoEm: now,
      );

      final json = m.toJson();
      final m2 = MensagemServico.fromJson(json);
      expect(m2.id, 'm-1');
      expect(m2.texto, 'Pagamento confirmado em custódia!');
      expect(m2.remetenteNome, 'Produtor Teste');
    });

    test('gerarUuidV4 produz UUIDs válidos e distintos', () {
      final u1 = gerarUuidV4();
      final u2 = gerarUuidV4();
      expect(u1, isNot(equals(u2)));
      final regex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(regex.hasMatch(u1), true, reason: '$u1 não é UUID v4 válido');
      expect(regex.hasMatch(u2), true, reason: '$u2 não é UUID v4 válido');
    });
  });

  group('SolicitacaoRepositorio (Sembast)', () {
    test('salvar, listar, listarPendentes e remover', () async {
      final db = await newDatabaseFactoryMemory().openDatabase('test_solicitacoes.db');
      final store = stringMapStoreFactory.store('solicitacoes');
      final repo = SolicitacaoRepositorio(db, store);

      final s1 = SolicitacaoServico(
        id: 's1',
        titulo: 'Instalação de Aeradores',
        valorEstimado: 500.0,
        criadoEm: DateTime(2026, 8, 27, 8, 0),
        sincronizado: false,
      );
      final s2 = SolicitacaoServico(
        id: 's2',
        titulo: 'Consultoria de Qualidade de Água',
        valorEstimado: 800.0,
        criadoEm: DateTime(2026, 8, 27, 9, 0),
        sincronizado: true,
      );

      await repo.salvar(s1);
      await repo.salvar(s2);

      final todas = await repo.listar();
      expect(todas.length, 2);
      expect(todas[0].id, 's2'); // mais recente primeiro
      expect(todas[1].id, 's1');

      final pendentes = await repo.listarPendentes();
      expect(pendentes.length, 1);
      expect(pendentes[0].id, 's1');

      await repo.remover('s1');
      final restantes = await repo.listar();
      expect(restantes.length, 1);
      expect(restantes[0].id, 's2');
    });
  });
}
