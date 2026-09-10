class ChatMessageModel {
  final String id;
  final String conversationId;
  final String sender; // USER, AGENT, ATTENDANT
  final String content;
  final bool isAbstained;
  final double? confidenceScore;
  final double? thresholdUsed;
  final List<dynamic>? retrievedChunks;
  final String? sourceCitation;
  final String? suggestedAction;
  final String agentVersion;
  final DateTime createdAt;
  bool? isHelpful;
  String? feedbackComment;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.isAbstained = false,
    this.confidenceScore,
    this.thresholdUsed,
    this.retrievedChunks,
    this.sourceCitation,
    this.suggestedAction,
    this.agentVersion = "asa-rag-v1.0",
    required this.createdAt,
    this.isHelpful,
    this.feedbackComment,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    bool? helpful;
    String? comment;
    if (json['feedback'] != null) {
      helpful = json['feedback']['is_helpful'];
      comment = json['feedback']['comment'];
    }

    return ChatMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      sender: json['sender'] ?? 'AGENT',
      content: json['content'] ?? '',
      isAbstained: json['is_abstained'] ?? false,
      confidenceScore: json['confidence_score'] != null ? (json['confidence_score'] as num).toDouble() : null,
      thresholdUsed: json['threshold_used'] != null ? (json['threshold_used'] as num).toDouble() : null,
      retrievedChunks: json['retrieved_chunks'],
      sourceCitation: json['source_citation'],
      suggestedAction: json['suggested_action'],
      agentVersion: json['agent_version'] ?? 'asa-rag-v1.0',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isHelpful: helpful,
      feedbackComment: comment,
    );
  }
}
