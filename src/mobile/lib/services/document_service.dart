import 'dart:convert';
import 'package:asa_connect/models/knowledge_document.dart';
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
}
