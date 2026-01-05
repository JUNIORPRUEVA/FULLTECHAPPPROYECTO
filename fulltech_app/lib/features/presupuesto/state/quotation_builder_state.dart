import '../models/quotation_models.dart';

class QuotationTicketDraft {
  final String id;
  final String name;
  final String? quotationId;
  final bool remoteCreated;
  final QuotationCustomerDraft? customer;
  final List<QuotationItemDraft> items;
  final bool itbisEnabled;
  final double itbisRate;

  const QuotationTicketDraft({
    required this.id,
    required this.name,
    required this.quotationId,
    required this.remoteCreated,
    required this.customer,
    required this.items,
    required this.itbisEnabled,
    required this.itbisRate,
  });

  factory QuotationTicketDraft.initial({
    required String id,
    required String name,
  }) {
    return QuotationTicketDraft(
      id: id,
      name: name,
      quotationId: null,
      remoteCreated: false,
      customer: null,
      items: const [],
      itbisEnabled: true,
      itbisRate: 0.18,
    );
  }

  QuotationTicketDraft copyWith({
    String? id,
    String? name,
    String? quotationId,
    bool? remoteCreated,
    QuotationCustomerDraft? customer,
    List<QuotationItemDraft>? items,
    bool? itbisEnabled,
    double? itbisRate,
  }) {
    return QuotationTicketDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      quotationId: quotationId ?? this.quotationId,
      remoteCreated: remoteCreated ?? this.remoteCreated,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      itbisEnabled: itbisEnabled ?? this.itbisEnabled,
      itbisRate: itbisRate ?? this.itbisRate,
    );
  }
}

class QuotationBuilderState {
  final bool isSaving;
  final String? error;

  final List<QuotationTicketDraft> tickets;
  final int activeTicketIndex;

  final bool skipAutoEditDialog;

  const QuotationBuilderState({
    required this.isSaving,
    required this.error,
    required this.tickets,
    required this.activeTicketIndex,
    required this.skipAutoEditDialog,
  });

  factory QuotationBuilderState.initial() {
    return const QuotationBuilderState(
      isSaving: false,
      error: null,
      tickets: [],
      activeTicketIndex: 0,
      skipAutoEditDialog: false,
    );
  }

  QuotationBuilderState copyWith({
    bool? isSaving,
    String? error,
    List<QuotationTicketDraft>? tickets,
    int? activeTicketIndex,
    bool? skipAutoEditDialog,
    bool clearError = false,
  }) {
    return QuotationBuilderState(
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      tickets: tickets ?? this.tickets,
      activeTicketIndex: activeTicketIndex ?? this.activeTicketIndex,
      skipAutoEditDialog: skipAutoEditDialog ?? this.skipAutoEditDialog,
    );
  }

  QuotationTicketDraft get activeTicket {
    if (tickets.isEmpty) {
      return QuotationTicketDraft.initial(id: 't0', name: 'Ticket 1');
    }
    final idx = activeTicketIndex.clamp(0, tickets.length - 1);
    return tickets[idx];
  }

  QuotationCustomerDraft? get customer => activeTicket.customer;

  List<QuotationItemDraft> get items => activeTicket.items;

  bool get itbisEnabled => activeTicket.itbisEnabled;

  double get itbisRate => activeTicket.itbisRate;

  double get grossSubtotal {
    double sum = 0;
    for (final it in items) {
      sum += it.lineGross;
    }
    return sum;
  }

  double get discountTotal {
    double sum = 0;
    for (final it in items) {
      sum += it.lineDiscount;
    }
    return sum;
  }

  double get subtotal =>
      (grossSubtotal - discountTotal).clamp(0, double.infinity);

  double get itbisAmount => itbisEnabled ? subtotal * itbisRate : 0;

  double get total => subtotal + itbisAmount;
}
