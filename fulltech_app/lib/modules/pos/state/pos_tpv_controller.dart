import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/offline_http_queue.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';
import '../models/pos_ticket.dart';
import '../services/pos_pricing.dart';

class PosSavedTpvState {
  final List<PosTicket> tickets;
  final String activeTicketId;

  const PosSavedTpvState({required this.tickets, required this.activeTicketId});
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
              customerPhone: null,
              customerRnc: null,
              discountType: PosDiscountType.fixed,
              discountValue: 0,
              itbisEnabled: false,
              itbisRate: 0.18,
              ncfEnabled: false,
              selectedNcfDocType: null,
              warrantyEnabled: false,
              selectedWarrantyId: null,
              selectedWarrantyName: null,
              items: [],
            ),
          ],
          activeTicketId: 'ticket-1',
          lastPaidSale: null,
        ),
      ) {
    unawaited(refreshProducts());
    unawaited(_restoreLocalTickets());
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

  Future<void> _restoreLocalTickets() async {
    try {
      final saved = await _repo.loadTpvTickets();
      if (saved == null) return;
      if (saved.tickets.isEmpty) return;
      final activeExists = saved.tickets.any(
        (t) => t.id == saved.activeTicketId,
      );

      state = state.copyWith(
        tickets: saved.tickets,
        activeTicketId: activeExists
            ? saved.activeTicketId
            : saved.tickets.first.id,
      );
    } catch (_) {
      // Best-effort restore.
    }
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_repo.saveTpvTickets(state.tickets, state.activeTicketId));
    });
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
      customerPhone: null,
      customerRnc: null,
      discountType: PosDiscountType.fixed,
      discountValue: 0,
      itbisEnabled: false,
      itbisRate: 0.18,
      ncfEnabled: false,
      selectedNcfDocType: null,
      warrantyEnabled: false,
      selectedWarrantyId: null,
      selectedWarrantyName: null,
      items: const [],
    );

    state = state.copyWith(
      tickets: [...state.tickets, ticket],
      activeTicketId: id,
    );

    _schedulePersist();
  }

  void renameTicket(String id, String name) {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    final tickets = state.tickets
        .map(
          (t) =>
              t.id == id ? t.copyWith(name: nextName, isCustomName: true) : t,
        )
        .toList();
    state = state.copyWith(tickets: tickets);
    _schedulePersist();
  }

  void closeTicket(String id) {
    final tickets = [...state.tickets];
    if (tickets.length == 1) return;
    tickets.removeWhere((t) => t.id == id);
    final active = state.activeTicketId == id
        ? tickets.first.id
        : state.activeTicketId;
    state = state.copyWith(tickets: tickets, activeTicketId: active);
    _schedulePersist();
  }

  void selectTicket(String id) {
    state = state.copyWith(activeTicketId: id);
    _schedulePersist();
  }

  void setCustomer({
    String? customerId,
    String? name,
    String? phone,
    String? rnc,
  }) {
    final t = state.activeTicket;
    final nextName = (name ?? '').trim();

    final shouldAutoName = !t.isCustomName && nextName.isNotEmpty;
    _updateTicket(
      t.copyWith(
        customerId: customerId,
        customerName: nextName.isEmpty ? null : nextName,
        customerPhone: (phone ?? '').trim().isEmpty
            ? null
            : (phone ?? '').trim(),
        customerRnc: (rnc ?? '').trim().isEmpty ? null : (rnc ?? '').trim(),
        name: shouldAutoName ? nextName : t.name,
      ),
    );
  }

  void setGlobalDiscount({
    required PosDiscountType type,
    required double value,
  }) {
    final t = state.activeTicket;
    final safeValue = value.isNaN || value.isInfinite ? 0.0 : value;
    _updateTicket(t.copyWith(discountType: type, discountValue: safeValue));
  }

  void setItbisEnabled(bool enabled) {
    final t = state.activeTicket;
    _updateTicket(t.copyWith(itbisEnabled: enabled));
  }

  void setItbisRatePercent(double percent) {
    final t = state.activeTicket;
    final p = percent.isNaN || percent.isInfinite ? 0.0 : percent;
    final rate = (p.clamp(0, 100) / 100.0).toDouble();
    _updateTicket(t.copyWith(itbisRate: rate));
  }

  void setNcfEnabled(bool enabled) {
    final t = state.activeTicket;
    _updateTicket(
      t.copyWith(
        ncfEnabled: enabled,
        selectedNcfDocType: enabled ? t.selectedNcfDocType : null,
      ),
    );
  }

  void setSelectedNcfDocType(String? docType) {
    final t = state.activeTicket;
    final next = (docType ?? '').trim();
    _updateTicket(t.copyWith(selectedNcfDocType: next.isEmpty ? null : next));
  }

  void setWarrantyEnabled(bool enabled) {
    final t = state.activeTicket;
    _updateTicket(
      t.copyWith(
        warrantyEnabled: enabled,
        selectedWarrantyId: enabled ? t.selectedWarrantyId : null,
        selectedWarrantyName: enabled ? t.selectedWarrantyName : null,
      ),
    );
  }

  void setSelectedWarranty({
    required String? warrantyId,
    required String? warrantyName,
  }) {
    final t = state.activeTicket;
    _updateTicket(
      t.copyWith(
        selectedWarrantyId: warrantyId,
        selectedWarrantyName: warrantyName,
        warrantyEnabled: warrantyId != null,
      ),
    );
  }

  void addProduct(PosProduct product) {
    final t = state.activeTicket;
    final items = [...t.items];

    final idx = items.indexWhere((it) => it.product.id == product.id);
    if (idx >= 0) {
      final current = items[idx];
      final next = current.copyWith(qty: current.qty + 1);
      if (!product.allowNegativeStock && next.qty > product.stockQty) {
        state = state.copyWith(
          error:
              'Stock insuficiente para ${product.nombre}. Disponible: ${product.stockQty.toStringAsFixed(0)}',
        );
        return;
      }
      items[idx] = next;
    } else {
      if (!product.allowNegativeStock && 1 > product.stockQty) {
        state = state.copyWith(
          error:
              'Stock insuficiente para ${product.nombre}. Disponible: ${product.stockQty.toStringAsFixed(0)}',
        );
        return;
      }
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

    if (!next.product.allowNegativeStock && next.qty > next.product.stockQty) {
      state = state.copyWith(
        error:
            'Stock insuficiente para ${next.product.nombre}. Disponible: ${next.product.stockQty.toStringAsFixed(0)}',
      );
      return;
    }

    final items = t.items
        .map((it) => it.product.id == line.product.id ? next : it)
        .toList();
    _updateTicket(t.copyWith(items: items));
  }

  void clearActiveTicket() {
    final t = state.activeTicket;
    final cleared = t.copyWith(
      items: const [],
      discountType: PosDiscountType.fixed,
      discountValue: 0,
      ncfEnabled: false,
      selectedNcfDocType: null,
      warrantyEnabled: false,
      selectedWarrantyId: null,
      selectedWarrantyName: null,
    );
    _updateTicket(cleared);
    state = state.copyWith(error: null);
  }

  Future<PosSale> cancelSale({required String saleId}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final canceled = await _repo.cancelSale(saleId: saleId);
      await refreshProducts();

      final last = state.lastPaidSale;
      if (last != null && last.id == saleId) {
        state = state.copyWith(loading: false, lastPaidSale: canceled);
      } else {
        state = state.copyWith(loading: false);
      }

      return canceled;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
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

    // Pricing computed locally for validation / payload.
    final pricing = computeTicketPricing(
      grossSubtotal: t.subtotal,
      lineDiscounts: t.lineDiscounts,
      discountType: t.discountType,
      discountValue: t.discountValue,
      itbisEnabled: t.itbisEnabled,
      itbisRate: t.itbisRate,
    );

    state = state.copyWith(loading: true, error: null);
    try {
      final sale = await _repo.createSale(
        invoiceType: t.ncfEnabled ? 'FISCAL' : 'NORMAL',
        customerId: t.customerId,
        customerName: t.customerName,
        customerRnc: t.customerRnc,
        items: t.items,
        discountTotal: pricing.globalDiscount,
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
      final cleared = t.copyWith(
        items: const [],
        discountType: PosDiscountType.fixed,
        discountValue: 0,
        ncfEnabled: false,
        selectedNcfDocType: null,
      );
      _updateTicket(cleared);

      state = state.copyWith(loading: false, lastPaidSale: paid);
      unawaited(refreshProducts());
      _schedulePersist();
      return paid;
    } catch (e) {
      // Offline-first: queue the checkout and clear the ticket so the user can continue.
      if (OfflineHttpQueue.isNetworkError(e)) {
        await _repo.queueOfflineCheckout(
          invoiceType: t.ncfEnabled ? 'FISCAL' : 'NORMAL',
          customerId: t.customerId,
          customerName: t.customerName,
          customerRnc: t.customerRnc,
          items: t.items,
          discountTotal: pricing.globalDiscount,
          paymentMethod: paymentMethod,
          paidAmount: paidAmount,
          receivedAmount: receivedAmount,
          dueDateIso: dueDate?.toIso8601String(),
          initialPayment: initialPayment,
          docType: docType,
          note: null,
        );

        final cleared = t.copyWith(
          items: const [],
          discountType: PosDiscountType.fixed,
          discountValue: 0,
          ncfEnabled: false,
          selectedNcfDocType: null,
        );
        _updateTicket(cleared);
        state = state.copyWith(loading: false, error: null);
        _schedulePersist();
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
    _schedulePersist();
  }
}
