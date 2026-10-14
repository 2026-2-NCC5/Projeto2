class EscalationModel {
  final int id;
  final String conversationId;
  final int studentId;
  final String? studentName;
  final String? studentRa;
  final int? assignedAttendantId;
  final String? assignedAttendantName;
  final String reason;
  final String? userNotes;
  final String priority;
  final String status;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  EscalationModel({
    required this.id,
    required this.conversationId,
    required this.studentId,
    this.studentName,
    this.studentRa,
    this.assignedAttendantId,
    this.assignedAttendantName,
    required this.reason,
    this.userNotes,
    required this.priority,
    required this.status,
    this.resolutionNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory EscalationModel.fromJson(Map<String, dynamic> json) {
    return EscalationModel(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? '',
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'],
      studentRa: json['student_ra'],
      assignedAttendantId: json['assigned_attendant_id'],
      assignedAttendantName: json['assigned_attendant_name'],
      reason: json['reason'] ?? '',
      userNotes: json['user_notes'],
      priority: json['priority'] ?? 'MEDIA',
      status: json['status'] ?? 'PENDENTE',
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    );
  }
}
