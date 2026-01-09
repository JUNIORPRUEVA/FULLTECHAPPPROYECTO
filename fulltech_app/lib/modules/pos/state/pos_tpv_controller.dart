import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/offline_http_queue.dart';
import '../domain/pos_pricing.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';

class PosTicket {
  final String id;
  final String name;
  final bool isCustomName;
  final String? customerId;
  final String? customerName;
  final String? customerRnc;
  final String invoiceType; // NORMAL|FISCAL
  final PosDiscount globalDiscount;
  final bool itbisEnabled;
  final double itbisRate;
  final String? fiscalDocType;
  final List<PosSaleItemDraft> items;

  const PosTicket({
    required this.id,
    required this.name,
    required this.isCustomName,
    required this.customerId,
    required this.customerName,
    required this.customerRnc,
    required this.invoiceType,
    required this.globalDiscount,
    required this.itbisEnabled,
    required this.itbisRate,
    required this.fiscalDocType,
    required this.items,
  });

  PosTicket copyWith({
    String? name,
    bool? isCustomName,
    String? customerId,
    String? customerName,
    String? customerRnc,
    String? invoiceType,
    double? globalDiscount,
    PosDiscount? globalDiscountNext,
    bool? itbisEnabled,
    double? itbisRate,
    String? fiscalDocType,
    bool clearFiscalDocType = false,
    List<PosSaleItemDraft>? items,
  }) {
    return PosTicket(
      id: id,
      name: name ?? this.name,
      isCustomName: isCustomName ?? this.isCustomName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerRnc: customerRnc ?? this.customerRnc,
      invoiceType: invoiceType ?? this.invoiceType,
      globalDiscount: globalDiscountNext ?? (globalDiscount != null ? PosDiscount(type: 'AMOUNT', value: globalDiscount) : this.globalDiscount),
      itbisEnabled: itbisEnabled ?? this.itbisEnabled,
      itbisRate: itbisRate ?? this.itbisRate,
      fiscalDocType: clearFiscalDocType ? null : (fiscalDocType ?? this.fiscalDocType),
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_custom_name': isCustomName,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_rnc': customerRnc,
      'invoice_type': invoiceType,
      'global_discount': globalDiscount.toJson(),
      'itbis_enabled': itbisEnabled,
      'itbis_rate': itbisRate,
      'fiscal_doc_type': fiscalDocType,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory PosTicket.fromJson(Map<String, dynamic> json) {
    final itemsRaw = (json['items'] as List?) ?? const [];
    final discountRaw = (json['global_discount'] as Map?)?.cast<String, dynamic>();
    return PosTicket(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Ticket').toString(),
      isCustomName: (json['is_custom_name'] is bool)
          ? (json['is_custom_name'] as bool)
          : ((json['is_custom_name'] ?? false).toString() == 'true'),
      customerId: (json['customer_id'] ?? '').toString().trim().isEmpty ? null : (json['customer_id'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString().trim().isEmpty ? null : (json['customer_name'] ?? '').toString(),
      customerRnc: (json['customer_rnc'] ?? '').toString().trim().isEmpty ? null : (json['customer_rnc'] ?? '').toString(),
      invoiceType: (json['invoice_type'] ?? 'NORMAL').toString(),
      globalDiscount: discountRaw == null ? PosDiscount.none : PosDiscount.fromJson(discountRaw),
      itbisEnabled: (json['itbis_enabled'] is bool)
          ? (json['itbis_enabled'] as bool)
          : ((json['itbis_enabled'] ?? false).toString() == 'true'),
      itbisRate: (json['itbis_rate'] is num) ? (json['itbis_rate'] as num).toDouble() : 0.18,
      fiscalDocType: (json['fiscal_doc_type'] ?? '').toString().trim().isEmpty
          ? null
          : (json['fiscal_doc_type'] ?? '').toString(),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => PosSaleItemDraft.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  double get subtotal =>
      items.fold<double>(0, (acc, it) => acc + (it.qty * it.unitPrice));
  double get lineDiscounts =>
      items.fold<double>(0, (acc, it) => acc + it.discountAmount);
  double get baseAfterLineDiscounts => items.fold<double>(
    0,
    (acc, it) => acc + (it.lineSubtotal < 0 ? 0 : it.lineSubtotal),
  );

  PosTicketTotals get totals => PosPricing.totals(
    grossSubtotal: subtotal,
    lineDiscounts: lineDiscounts,
    baseAfterLineDiscounts: baseAfterLineDiscounts,
    globalDiscount: globalDiscount,
    itbisEnabled: itbisEnabled,
    itbisRate: itbisRate,
  );
}

class PosTpvState {
  final bool loading;
  final String? error;

  final String search;
  final bool lowStockOnly;
  final String? categoryId;

  final List<PosProduct> products;

  final List<PosTicket> tickets;
  final String activeTicketId;

  final PosSale? lastPaidSale;

  const PosTpvState({
    required this.loading,
    required this.error,
    required this.search,
    required this.lowStockOnly,
    required this.categoryId,
    required this.products,
    required this.tickets,
    required this.activeTicketId,
    required this.lastPaidSale,
  });

  PosTicket get activeTicket =>
      tickets.firstWhere((t) => t.id == activeTicketId);

  PosTpvState copyWith({
    bool? loading,
    String? error,
    String? search,
    bool? lowStockOnly,
    String? categoryId,
    List<PosProduct>? products,
    List<PosTicket>? tickets,
    String? activeTicketId,
    PosSale? lastPaidSale,
  }) {
    return PosTpvState(
      loading: loading ?? this.loading,
      error: error,
      search: search ?? this.search,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      categoryId: categoryId ?? this.categoryId,
      products: products ?? this.products,
      tickets: tickets ?? this.tickets,
      activeTicketId: activeTicketId ?? this.activeTicketId,
      lastPaidSale: lastPaidSale,
    );
  }
}

class PosTpvController extends StateNotifier<PosTpvState> {
  PosTpvController({required PosRepository repo})
    : _repo = repo,
      super(
        PosTpvState(
          loading: false,
          error: null,
          search: '',
          lowStockOnly: false,
          categoryId: null,
          products: const [],
          tickets: const [
            PosTicket(
              id: 'ticket-1',
              name: 'Ticket 1',
              isCustomName: false,
              customerId: null,
              customerName: null,
              customerRnc: null,
              invoiceType: 'NORMAL',
              globalDiscount: PosDiscount.none,
              itbisEnabled: false,
              itbisRate: 0.18,
              fiscalDocType: 'B02',
              items: [],
            ),
          ],
          activeTicketId: 'ticket-1',
          lastPaidSale: null,
        ),
      ) {
    unawaited(_loadDraft());
    unawaited(refreshProducts());
  }

  final PosRepository _repo;
  Timer? _debounce;
  Timer? _persistDebounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _persistDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final jsonStr = await _repo.loadTpvDraftJson();
      if (jsonStr == null || jsonStr.trim().isEmpty) return;
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return;

      final ticketsRaw = (decoded['tickets'] as List?) ?? const [];
      final tickets = ticketsRaw
          .whereType<Map>()
          .map((e) => PosTicket.fromJson(e.cast<String, dynamic>()))
          .where((t) => t.id.trim().isNotEmpty)
          .toList();
      if (tickets.isEmpty) return;

      final activeId = (decoded['active_ticket_id'] ?? '').toString();
      final safeActive = tickets.any((t) => t.id == activeId) ? activeId : tickets.first.id;

      state = state.copyWith(tickets: tickets, activeTicketId: safeActive);
    } catch (_) {
      // Ignore draft restore errors.
    }
  }

  void _schedulePersistDraft() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    final payload = {
      'active_ticket_id': state.activeTicketId,
      'tickets': state.tickets.map((t) => t.toJson()).toList(),
    };
    await _repo.saveTpvDraftJson(jsonEncode(payload));
  }

  Future<void> refreshProducts() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final products = await _repo.listAllProducts(
        search: state.search,
        lowStock: state.lowStockOnly,
        categoryId: state.categoryId,
      );
      state = state.copyWith(loading: false, products: products);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refreshProducts());
    });
  }

  void setCategory(String? id) {
    state = state.copyWith(categoryId: id);
    unawaited(refreshProducts());
  }

  void toggleLowStockOnly(bool v) {
    state = state.copyWith(lowStockOnly: v);
    unawaited(refreshProducts());
  }

  void addTicket() {
    final n = state.tickets.length + 1;
    final id = 'ticket-$n-${DateTime.now().microsecondsSinceEpoch}';
    final ticket = PosTicket(
      id: id,
      name: 'Ticket $n',
      isCustomName: false,
      customerId: null,
      customerName: null,
      customerRnc: null,
      invoiceType: 'NORMAL',
      globalDiscount: PosDiscount.none,
      itbisEnabled: false,
      itbisRate: 0.18,
      fiscalDocType: 'B02',
      items: const [],
    );

    state = state.copyWith(
      tickets: [...state.tickets, ticket],
      activeTicketId: id,
    );
    _schedulePersistDraft();
  }

  void renameTicket(String id, String name) {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    final tickets = state.tickets
        .map((t) => t.id == id ? t.copyWith(name: nextName, isCustomName: true) : t)
        .toList();
    state = state.copyWith(tickets: tickets);
    _schedulePersistDraft();
  }

  void closeTicket(String id) {
    final tickets = [...state.tickets];
    if (tickets.length == 1) return;
    tickets.removeWhere((t) => t.id == id);
    final active = state.activeTicketId == id
        ? tickets.first.id
        : state.activeTicketId;
    state = state.copyWith(tickets: tickets, activeTicketId: active);
    _schedulePersistDraft();
  }

  void selectTicket(String id) {
    state = state.copyWith(activeTicketId: id);
    _schedulePersistDraft();
  }

  void setInvoiceType(String invoiceType) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(invoiceType: invoiceType));
  }

  void setCustomer({String? customerId, String? name, String? rnc}) {
    final t = state.activeTicket;
    final cleanedName = (name ?? '').trim();
    final shouldAutoName = !t.isCustomName;
    final label = (shouldAutoName && cleanedName.isNotEmpty) ? cleanedName : t.name;
    _updateTicket(
      t.copyWith(
        customerId: customerId,
        customerName: name,
        customerRnc: rnc,
        name: label,
      ),
    );
  }

  void setGlobalDiscount(PosDiscount discount) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(globalDiscountNext: discount));
  }

  void setItbisEnabled(bool enabled) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(itbisEnabled: enabled));
  }

  void setItbisRate(double rate) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(itbisRate: rate < 0 ? 0 : rate));
  }

  void setFiscalDocType(String? docType) {
    final t = state.activeTicket;
    final cleaned = (docType ?? '').trim();
    _updateTicket(t.copyWith(fiscalDocType: cleaned.isEmpty ? null : cleaned));
  }

  void addProduct(PosProduct product) {
    final t = state.activeTicket;
    final items = [...t.items];

    final idx = items.indexWhere((it) => it.product.id == product.id);
    if (idx >= 0) {
      final current = items[idx];
      items[idx] = current.copyWith(qty: current.qty + 1);
    } else {
      items.add(
        PosSaleItemDraft(
          product: product,
          qty: 1,
          unitPrice: product.precioVenta,
          discountAmount: 0,
        ),
      );
    }

    _updateTicket(t.copyWith(items: items));
  }

  void updateLine(PosSaleItemDraft line, PosSaleItemDraft next) {
    final t = state.activeTicket;
    final items = t.items
        .map((it) => it.product.id == line.product.id ? next : it)
        .toList();
    _updateTicket(t.copyWith(items: items));
  }

  void removeLine(PosSaleItemDraft line) {
    final t = state.activeTicket;
    _updateTicket(
      t.copyWith(
        items: t.items.where((it) => it.product.id != line.product.id).toList(),
      ),
    );
  }

  Future<PosSale?> checkout({
    required String paymentMethod,
    required double paidAmount,
    double? receivedAmount,
    DateTime? dueDate,
    double initialPayment = 0,
    String? docType,
  }) async {
    final t = state.activeTicket;
    if (t.items.isEmpty) {
      throw StateError('El carrito está vacío');
    }

    if (t.invoiceType == 'FISCAL') {
      final rnc = (t.customerRnc ?? '').trim();
      if (rnc.isEmpty) {
        throw StateError('Para comprobante fiscal, el cliente debe tener RNC');
      }
      final dt = (docType ?? t.fiscalDocType ?? '').trim();
      if (dt.isEmpty) {
        throw StateError('Selecciona el tipo de comprobante (NCF)');
      }
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final sale = await _repo.createSale(
        invoiceType: t.invoiceType,
        customerId: t.customerId,
        customerName: t.customerName,
        customerRnc: t.customerRnc,
        items: t.items,
        discountTotal: t.totals.globalDiscount,
      );

      final paid = await _repo.paySale(
        saleId: sale.id,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        receivedAmount: receivedAmount,
        dueDateIso: dueDate?.toIso8601String(),
        initialPayment: initialPayment,
        docType: t.invoiceType == 'FISCAL' ? (docType ?? t.fiscalDocType) : null,
        customerRnc: t.customerRnc,
      );

      // Clear current ticket after payment.
      final cleared = t.copyWith(items: const [], globalDiscountNext: PosDiscount.none);
      _updateTicket(cleared);

      state = state.copyWith(loading: false, lastPaidSale: paid);
      return paid;
    } catch (e) {
      // Offline-first: queue the checkout and clear the ticket so the user can continue.
      if (OfflineHttpQueue.isNetworkError(e)) {
        if (t.invoiceType == 'FISCAL') {
          state = state.copyWith(loading: false, error: null);
          throw StateError('Para emitir comprobante fiscal (NCF) se requiere internet');
        }

        await _repo.queueOfflineCheckout(
          invoiceType: t.invoiceType,
          customerId: t.customerId,
          customerName: t.customerName,
          customerRnc: t.customerRnc,
          items: t.items,
          discountTotal: t.totals.globalDiscount,
          paymentMethod: paymentMethod,
          paidAmount: paidAmount,
          receivedAmount: receivedAmount,
          dueDateIso: dueDate?.toIso8601String(),
          initialPayment: initialPayment,
          docType: docType,
          note: null,
        );

        final cleared = t.copyWith(items: const [], globalDiscountNext: PosDiscount.none);
        _updateTicket(cleared);
        state = state.copyWith(loading: false, error: null);
        return null;
      }

      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  void _updateTicket(PosTicket next) {
    final tickets = state.tickets
        .map((t) => t.id == next.id ? next : t)
        .toList();
    state = state.copyWith(tickets: tickets);
    _schedulePersistDraft();
  }
}
