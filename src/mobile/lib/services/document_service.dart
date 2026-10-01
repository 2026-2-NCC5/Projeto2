import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asa_connect/models/knowledge_document.dart';
import 'package:asa_connect/models/student_document.dart';
import 'package:asa_connect/services/api_client.dart';

class DocumentService {
  final ApiClient _client = ApiClient();

  Future<List<KnowledgeDocumentModel>> getDocuments({bool activeOnly = true}) async {
    final response = await _client.get('/documents?active_only=$activeOnly');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((item) => KnowledgeDocumentModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar documentos institucionais.');
    }
  }

  Future<KnowledgeDocumentModel> getDocumentBySlug(String slug) async {
    final response = await _client.get('/documents/$slug');
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return KnowledgeDocumentModel.fromJson(data);
    } else {
      throw Exception('Erro ao carregar detalhe do documento.');
    }
  }

  /// Realiza o upload real de documento do estudante
  Future<StudentDocumentUploadResult> uploadStudentDocument({
    String? filePath,
    List<int>? fileBytes,
    required String filename,
    String category = 'Geral',
  }) async {
    final uri = Uri.parse('${_client.baseUrl}/documents/upload');
    final request = http.MultipartRequest('POST', uri);

    if (_client.token != null && _client.token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${_client.token}';
    }
    request.headers['Accept'] = 'application/json';
    request.fields['category'] = category;

    if (filePath != null && filePath.isNotEmpty) {
      final file = await http.MultipartFile.fromPath('file', filePath, filename: filename);
      request.files.add(file);
    } else if (fileBytes != null) {
      final file = http.MultipartFile.fromBytes('file', fileBytes, filename: filename);
      request.files.add(file);
    } else {
      throw Exception('Nenhum dado de arquivo fornecido para upload.');
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return StudentDocumentUploadResult.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['detail'] ?? 'Erro ao realizar upload do arquivo.');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) rethrow;
        throw Exception('Falha no upload do arquivo (HTTP ${response.statusCode}).');
      }
    }
  }

  /// Lista os documentos enviados pelo estudante logado
  Future<List<StudentDocumentModel>> getMyDocuments() async {
    final response = await _client.get('/documents/my-documents');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((item) => StudentDocumentModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar lista de documentos do estudante.');
    }
  }
}
