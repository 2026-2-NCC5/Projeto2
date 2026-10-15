class StudentDocumentModel {
  final int id;
  final int userId;
  final String filename;
  final String originalFilename;
  final int fileSize;
  final String mimeType;
  final String category;
  final String status;
  final String? analysisNotes;
  final DateTime createdAt;

  StudentDocumentModel({
    required this.id,
    required this.userId,
    required this.filename,
    required this.originalFilename,
    required this.fileSize,
    required this.mimeType,
    required this.category,
    required this.status,
    this.analysisNotes,
    required this.createdAt,
  });

  /// Retorna o tamanho formatado em KB ou MB
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json) {
    return StudentDocumentModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      filename: json['filename'] as String? ?? '',
      originalFilename: json['original_filename'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      category: json['category'] as String? ?? 'Geral',
      status: json['status'] as String? ?? 'RECEBIDO',
      analysisNotes: json['analysis_notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'filename': filename,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'mime_type': mimeType,
      'category': category,
      'status': status,
      'analysis_notes': analysisNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StudentDocumentUploadResult {
  final StudentDocumentModel document;
  final String message;
  final String? aiFeedback;

  StudentDocumentUploadResult({
    required this.document,
    required this.message,
    this.aiFeedback,
  });

  factory StudentDocumentUploadResult.fromJson(Map<String, dynamic> json) {
    return StudentDocumentUploadResult(
      document: StudentDocumentModel.fromJson(json['document'] as Map<String, dynamic>),
      message: json['message'] as String? ?? 'Upload realizado com sucesso.',
      aiFeedback: json['ai_feedback'] as String?,
    );
  }
}
