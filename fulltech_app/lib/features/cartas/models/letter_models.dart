// Cartas Models
class Letter {
  final String id;
  final String empresaId;
  final String userId;
  final String? quotationId;
  // Carta-from-Presupuesto fields (optional; present when using /api/cartas)
  final String? presupuestoId;
  final String? clienteId;
  final String? pdfPath;
  final String? userInstructions;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String letterType;
  final String subject;
  final String body;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Letter({
    required this.id,
    required this.empresaId,
    required this.userId,
    this.quotationId,
    this.presupuestoId,
    this.clienteId,
    this.pdfPath,
    this.userInstructions,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.letterType,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String,
      userId: json['user_id'] as String,
      quotationId: json['quotation_id'] as String?,
      presupuestoId: json['presupuesto_id'] as String?,
      clienteId: json['cliente_id'] as String?,
      pdfPath: json['pdf_path'] as String?,
      userInstructions: json['user_instructions'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      letterType: json['letter_type'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'user_id': userId,
      'quotation_id': quotationId,
      'presupuesto_id': presupuestoId,
      'cliente_id': clienteId,
      'pdf_path': pdfPath,
      'user_instructions': userInstructions,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'letter_type': letterType,
      'subject': subject,
      'body': body,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GenerateLetterRequest {
  final String letterType;
  final String tone;
  final String? quotationId;
  final CustomerInfo? customer;
  final String? context;
  final String? details;

  GenerateLetterRequest({
    required this.letterType,
    this.tone = 'Formal',
    this.quotationId,
    this.customer,
    this.context,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'letterType': letterType,
      'tone': tone,
      if (quotationId != null) 'quotationId': quotationId,
      if (customer != null)
        'customer': {
          'name': customer!.name,
          if (customer!.phone != null) 'phone': customer!.phone,
          if (customer!.email != null) 'email': customer!.email,
        },
      if (context != null) 'context': context,
      if (details != null) 'details': details,
    };
  }
}

class CustomerInfo {
  final String name;
  final String? phone;
  final String? email;

  CustomerInfo({required this.name, this.phone, this.email});
}

class GenerateLetterResponse {
  final String subject;
  final String body;

  GenerateLetterResponse({required this.subject, required this.body});

  factory GenerateLetterResponse.fromJson(Map<String, dynamic> json) {
    return GenerateLetterResponse(
      subject: json['subject'] as String,
      body: json['body'] as String,
    );
  }
}

class CreateLetterRequest {
  final String? quotationId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String letterType;
  final String subject;
  final String body;
  final String status;

  CreateLetterRequest({
    this.quotationId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.letterType,
    required this.subject,
    required this.body,
    this.status = 'DRAFT',
  });

  Map<String, dynamic> toJson() {
    return {
      if (quotationId != null) 'quotationId': quotationId,
      'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'letterType': letterType,
      'subject': subject,
      'body': body,
      'status': status,
    };
  }
}

class GenerateCartaRequest {
  final String presupuestoId;
  final bool attachQuotation;
  final String? cotizacionId;
  final String? clienteId;
  final String? customerName;
  final String? customerPhone;
  final String letterType;
  final String subject;
  final String userInstructions;

  const GenerateCartaRequest({
    required this.presupuestoId,
    required this.attachQuotation,
    this.cotizacionId,
    this.clienteId,
    this.customerName,
    this.customerPhone,
    required this.letterType,
    required this.subject,
    required this.userInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'presupuestoId': presupuestoId,
      'attachQuotation': attachQuotation,
      if (cotizacionId != null) 'cotizacionId': cotizacionId,
      if (clienteId != null) 'clienteId': clienteId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'letterType': letterType,
      'subject': subject,
      'userInstructions': userInstructions,
    };
  }
}
