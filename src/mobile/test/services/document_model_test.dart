import 'package:flutter_test/flutter_test.dart';
import 'package:asa_connect/models/student_document.dart';

void main() {
  group('StudentDocumentModel Tests', () {
    test('Converte JSON para StudentDocumentModel e formata tamanhos de arquivo', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'filename': 'abc_comprovante.pdf',
        'original_filename': 'Comprovante_Matricula.pdf',
        'file_size': 1572864, // 1.5 MB
        'mime_type': 'application/pdf',
        'category': 'Matrícula',
        'status': 'RECEBIDO',
        'analysis_notes': 'Comprovante válido',
        'created_at': '2024-03-10T14:30:00Z',
      };

      final doc = StudentDocumentModel.fromJson(json);

      expect(doc.id, equals(10));
      expect(doc.userId, equals(1));
      expect(doc.originalFilename, equals('Comprovante_Matricula.pdf'));
      expect(doc.category, equals('Matrícula'));
      expect(doc.formattedSize, equals('1.5 MB'));
      expect(doc.analysisNotes, equals('Comprovante válido'));
    });

    test('Formata tamanhos pequenos em KB e Bytes', () {
      final docBytes = StudentDocumentModel(
        id: 1,
        userId: 1,
        filename: 'f.txt',
        originalFilename: 'f.txt',
        fileSize: 500,
        mimeType: 'text/plain',
        category: 'Geral',
        status: 'RECEBIDO',
        createdAt: DateTime.now(),
      );
      expect(docBytes.formattedSize, equals('500 B'));

      final docKb = StudentDocumentModel(
        id: 2,
        userId: 1,
        filename: 'f.pdf',
        originalFilename: 'f.pdf',
        fileSize: 450000,
        mimeType: 'application/pdf',
        category: 'Geral',
        status: 'RECEBIDO',
        createdAt: DateTime.now(),
      );
      expect(docKb.formattedSize, equals('439.5 KB'));
    });

    test('Converte JSON para StudentDocumentUploadResult', () {
      final json = {
        'document': {
          'id': 1,
          'user_id': 1,
          'filename': 'xyz.png',
          'original_filename': 'rg.png',
          'file_size': 204800,
          'mime_type': 'image/png',
          'category': 'Documentos',
          'status': 'RECEBIDO',
          'analysis_notes': 'Imagem legível',
          'created_at': '2024-03-10T14:30:00Z',
        },
        'message': 'Arquivo enviado com sucesso!',
        'ai_feedback': 'Documento com QR Code identificado.',
      };

      final result = StudentDocumentUploadResult.fromJson(json);
      expect(result.message, equals('Arquivo enviado com sucesso!'));
      expect(result.aiFeedback, equals('Documento com QR Code identificado.'));
      expect(result.document.originalFilename, equals('rg.png'));
    });
  });
}
