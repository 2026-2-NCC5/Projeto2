class KnowledgeDocumentModel {
  final int id;
  final String title;
  final String slug;
  final String category;
  final String officialSource;
  final String section;
  final String version;
  final String? summary;
  final bool isActive;
  final DateTime updatedAt;
  final String? content;

  KnowledgeDocumentModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.officialSource,
    required this.section,
    this.version = "v1.0",
    this.summary,
    this.isActive = true,
    required this.updatedAt,
    this.content,
  });

  factory KnowledgeDocumentModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocumentModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'Geral',
      officialSource: json['official_source'] ?? 'Secretaria Geral',
      section: json['section'] ?? '',
      version: json['version'] ?? 'v1.0',
      summary: json['summary'],
      isActive: json['is_active'] ?? true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      content: json['content'],
    );
  }
}
