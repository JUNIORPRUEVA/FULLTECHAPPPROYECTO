import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/offline_http_queue.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';

class PosTicket {
  final String id;
  final String name;
  final String? customerId;
  final String? customerName;
  final String? customerRnc;
  final String invoiceType; // NORMAL|FISCAL
  final double globalDiscount;
  final List<PosSaleItemDraft> items;

  const PosTicket({
    required this.id,
    required this.name,
    required this.customerId,
    required this.customerName,
    required this.customerRnc,
    required this.invoiceType,
    required this.globalDiscount,
    required this.items,
  });

  PosTicket copyWith({
    String? name,
    String? customerId,
    String? customerName,
    String? customerRnc,
    String? invoiceType,
    double? globalDiscount,
    List<PosSaleItemDraft>? items,
  }) {
    return PosTicket(
      id: id,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerRnc: customerRnc ?? this.customerRnc,
      invoiceType: invoiceType ?? this.invoiceType,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      items: items ?? this.items,
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
              customerId: null,
              customerName: null,
              customerRnc: null,
              invoiceType: 'NORMAL',
              globalDiscount: 0,
              items: [],
            ),
          ],
          activeTicketId: 'ticket-1',
          lastPaidSale: null,
        ),
      ) {
    unawaited(refreshProducts());
  }

  final PosRepository _repo;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
      customerId: null,
      customerName: null,
      customerRnc: null,
      invoiceType: 'NORMAL',
      globalDiscount: 0,
      items: const [],
    );

    state = state.copyWith(
      tickets: [...state.tickets, ticket],
      activeTicketId: id,
    );
  }

  void renameTicket(String id, String name) {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    final tickets = state.tickets
        .map((t) => t.id == id ? t.copyWith(name: nextName) : t)
        .toList();
    state = state.copyWith(tickets: tickets);
  }

  void closeTicket(String id) {
    final tickets = [...state.tickets];
    if (tickets.length == 1) return;
    tickets.removeWhere((t) => t.id == id);
    final active = state.activeTicketId == id
        ? tickets.first.id
        : state.activeTicketId;
    state = state.copyWith(tickets: tickets, activeTicketId: active);
  }

  void selectTicket(String id) {
    state = state.copyWith(activeTicketId: id);
  }

  void setInvoiceType(String invoiceType) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(invoiceType: invoiceType));
  }

  void setCustomer({String? customerId, String? name, String? rnc}) {
    final t = state.activeTicket;
    final label = (name ?? '').trim().isEmpty ? t.name : name!.trim();
    _updateTicket(
      t.copyWith(
        customerId: customerId,
        customerName: name,
        customerRnc: rnc,
        name: label,
      ),
    );
  }

  void setGlobalDiscount(double amount) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(globalDiscount: amount < 0 ? 0 : amount));
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

    state = state.copyWith(loading: true, error: null);
    try {
      final sale = await _repo.createSale(
        invoiceType: t.invoiceType,
        customerId: t.customerId,
        customerName: t.customerName,
        customerRnc: t.customerRnc,
        items: t.items,
        discountTotal: t.globalDiscount,
      );

      final paid = await _repo.paySale(
        saleId: sale.id,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        receivedAmount: receivedAmount,
        dueDateIso: dueDate?.toIso8601String(),
        initialPayment: initialPayment,
        docType: docType,
        customerRnc: t.customerRnc,
      );

      // Clear current ticket after payment.
      final cleared = t.copyWith(items: const [], globalDiscount: 0);
      _updateTicket(cleared);

      state = state.copyWith(loading: false, lastPaidSale: paid);
      return paid;
    } catch (e) {
      // Offline-first: queue the checkout and clear the ticket so the user can continue.
      if (OfflineHttpQueue.isNetworkError(e)) {
        await _repo.queueOfflineCheckout(
          invoiceType: t.invoiceType,
          customerId: t.customerId,
          customerName: t.customerName,
          customerRnc: t.customerRnc,
          items: t.items,
          discountTotal: t.globalDiscount,
          paymentMethod: paymentMethod,
          paidAmount: paidAmount,
          receivedAmount: receivedAmount,
          dueDateIso: dueDate?.toIso8601String(),
          initialPayment: initialPayment,
          docType: docType,
          note: null,
        );

        final cleared = t.copyWith(items: const [], globalDiscount: 0);
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
  }
}
