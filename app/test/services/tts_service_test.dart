import 'package:flutter_test/flutter_test.dart';
import 'package:asa_connect/services/tts_service.dart';

void main() {
  group('TtsService - Sanitização de Markdown para Leitura Acessível', () {
    test('Remove formatações de negrito e itálico', () {
      const input = 'O prazo de rematrícula é **improrrogável** até o dia *15 de fevereiro*.';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('O prazo de rematrícula é improrrogável até o dia 15 de fevereiro.'));
    });

    test('Converte links Markdown em texto legível sem pronunciar URL técnica', () {
      const input = 'Acesse o [Portal do Aluno](https://aluno.fecap.br/login) para emitir seu boleto.';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('Acesse o Portal do Aluno para emitir seu boleto.'));
    });

    test('Remove marcadores de cabeçalho Markdown (#, ##, ###)', () {
      const input = '### Instruções de Matrícula\n# 1. Documentos Obrigatórios';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('Instruções de Matrícula\nDocumentos Obrigatórios'));
    });

    test('Limpa listas com marcadores (*, -, •)', () {
      const input = '- RG ou CNH\n* Histórico Escolar\n• Comprovante de Residência';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('RG ou CNH\nHistórico Escolar\nComprovante de Residência'));
    });

    test('Substitui URLs avulsas por link institucional', () {
      const input = 'Para mais detalhes consulte https://fecap.br/secretaria.';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('Para mais detalhes consulte link institucional.'));
    });

    test('Remove blocos de código e backticks', () {
      const input = 'Execute o comando `solicitar_atestado` ou consulte ```código interno``` na secretaria.';
      final output = TtsService.cleanMarkdownForSpeech(input);
      expect(output, equals('Execute o comando solicitar_atestado ou consulte na secretaria.'));
    });

    test('Lida com texto vazio ou apenas espaços', () {
      expect(TtsService.cleanMarkdownForSpeech(''), equals(''));
      expect(TtsService.cleanMarkdownForSpeech('   '), equals(''));
    });
  });
}
