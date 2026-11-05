class EscalationModel {
  final int id;
  final String? ticketNumber;
  final String modality; // PRESENCIAL ou ONLINE
  final String conversationId;
  final int studentId;
  final String? studentName;
  final String? studentRa;
  final String? studentEmail;
  final String? studentCourse;
  final int? studentSemester;
  final String? studentCampus;
  final int? assignedAttendantId;
  final String? assignedAttendantName;
  final String reason;
  final String? userNotes;
  final String priority;
  final String status;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int? serviceRating;
  final String? serviceRatingComment;

  EscalationModel({
    required this.id,
    this.ticketNumber,
    this.modality = 'ONLINE',
    required this.conversationId,
    required this.studentId,
    this.studentName,
    this.studentRa,
    this.studentEmail,
    this.studentCourse,
    this.studentSemester,
    this.studentCampus,
    this.assignedAttendantId,
    this.assignedAttendantName,
    required this.reason,
    this.userNotes,
    required this.priority,
    required this.status,
    this.resolutionNotes,
    required this.createdAt,
    this.resolvedAt,
    this.serviceRating,
    this.serviceRatingComment,
  });

  factory EscalationModel.fromJson(Map<String, dynamic> json) {
    return EscalationModel(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'],
      modality: json['modality'] ?? 'ONLINE',
      conversationId: json['conversation_id'] ?? '',
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'],
      studentRa: json['student_ra'],
      studentEmail: json['student_email'],
      studentCourse: json['student_course'],
      studentSemester: json['student_semester'],
      studentCampus: json['student_campus'],
      assignedAttendantId: json['assigned_attendant_id'],
      assignedAttendantName: json['assigned_attendant_name'],
      reason: json['reason'] ?? '',
      userNotes: json['user_notes'],
      priority: json['priority'] ?? 'MEDIA',
      status: json['status'] ?? 'PENDENTE',
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      serviceRating: json['service_rating'],
      serviceRatingComment: json['service_rating_comment'],
    );
  }
}
