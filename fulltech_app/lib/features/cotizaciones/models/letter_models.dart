class LetterType {
  static const garantia = 'GARANTIA';
  static const agradecimiento = 'AGRADECIMIENTO';
  static const seguimiento = 'SEGUIMIENTO';
  static const confirmacionInstalacion = 'CONFIRMACION_INSTALACION';
  static const recordatorioPago = 'RECORDATORIO_PAGO';
  static const rechazo = 'RECHAZO';
  static const personalizada = 'PERSONALIZADA';

  static const all = <String>[
    garantia,
    agradecimiento,
    seguimiento,
    confirmacionInstalacion,
    recordatorioPago,
    rechazo,
    personalizada,
  ];
}

class LetterStatus {
  static const draft = 'DRAFT';
  static const sent = 'SENT';

  static const all = <String>[draft, sent];
}

class SyncStatus {
  static const pending = 'pending';
  static const synced = 'synced';
  static const error = 'error';
}

class LetterRecord {
  final String id;
  final String empresaId;
  final String userId;

  final String? quotationId;

  final String customerName;
  final String? customerPhone;
  final String? customerEmail;

  final String letterType;
  final String subject;
  final String body;
  final String status;

  final String createdAt;
  final String updatedAt;

  final String syncStatus;
  final String? lastError;

  const LetterRecord({
    required this.id,
    required this.empresaId,
    required this.userId,
    required this.quotationId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.letterType,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.lastError,
  });

  factory LetterRecord.fromLocalRow(Map<String, Object?> row) {
    return LetterRecord(
      id: row['id'] as String,
      empresaId: row['empresa_id'] as String,
      userId: row['user_id'] as String,
      quotationId: row['quotation_id'] as String?,
      customerName: (row['customer_name'] ?? '') as String,
      customerPhone: row['customer_phone'] as String?,
      customerEmail: row['customer_email'] as String?,
      letterType: (row['letter_type'] ?? '') as String,
      subject: (row['subject'] ?? '') as String,
      body: (row['body'] ?? '') as String,
      status: (row['status'] ?? '') as String,
      createdAt: (row['created_at'] ?? '') as String,
      updatedAt: (row['updated_at'] ?? '') as String,
      syncStatus: (row['sync_status'] ?? SyncStatus.pending) as String,
      lastError: row['last_error'] as String?,
    );
  }

  /// Prisma responses use snake_case field names (e.g. customer_name).
  factory LetterRecord.fromServerJson(
    Map<String, dynamic> json, {
    required String empresaId,
    required String syncStatus,
  }) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return '';
    }

    String? pickStringNullable(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String) {
          final t = v.trim();
          if (t.isNotEmpty) return t;
        }
      }
      return null;
    }

    return LetterRecord(
      id: pickString(['id']),
      empresaId: empresaId,
      userId: pickString(['user_id', 'userId']),
      quotationId: pickStringNullable(['quotation_id', 'quotationId']),
      customerName: pickString(['customer_name', 'customerName']),
      customerPhone: pickStringNullable(['customer_phone', 'customerPhone']),
      customerEmail: pickStringNullable(['customer_email', 'customerEmail']),
      letterType: pickString(['letter_type', 'letterType']),
      subject: pickString(['subject']),
      body: pickString(['body']),
      status: pickString(['status']),
      createdAt: pickString(['created_at', 'createdAt']),
      updatedAt: pickString(['updated_at', 'updatedAt']),
      syncStatus: syncStatus,
      lastError: null,
    );
  }

  Map<String, Object?> toLocalRow({String? overrideId}) {
    return {
      'id': overrideId ?? id,
      'empresa_id': empresaId,
      'user_id': userId,
      'quotation_id': quotationId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'letter_type': letterType,
      'subject': subject,
      'body': body,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'last_error': lastError,
      'deleted_at': null,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'quotationId': quotationId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'letterType': letterType,
      'subject': subject,
      'body': body,
      'status': status,
    };
  }

  LetterRecord copyWith({
    String? id,
    String? empresaId,
    String? userId,
    String? quotationId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? letterType,
    String? subject,
    String? body,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    String? lastError,
  }) {
    return LetterRecord(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      userId: userId ?? this.userId,
      quotationId: quotationId ?? this.quotationId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      letterType: letterType ?? this.letterType,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}
