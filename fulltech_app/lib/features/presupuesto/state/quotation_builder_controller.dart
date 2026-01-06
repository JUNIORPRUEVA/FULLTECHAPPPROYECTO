import 'dart:math';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../../core/storage/local_db.dart';
import '../data/quotation_api.dart';
import '../models/quotation_models.dart';
import 'quotation_builder_state.dart';

final quotationApiProvider = Provider<QuotationApi>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return QuotationApi(dio);
});

final quotationBuilderControllerProvider =
    StateNotifierProvider<QuotationBuilderController, QuotationBuilderState>((
      ref,
    ) {
      final api = ref.watch(quotationApiProvider);
      final db = ref.watch(localDbProvider);
      final auth = ref.watch(authControllerProvider);
      final role = auth is AuthAuthenticated ? auth.user.role : 'unknown';

      return QuotationBuilderController(api: api, role: role, db: db);
    });

class QuotationBuilderController extends StateNotifier<QuotationBuilderState> {
  final QuotationApi _api;
  final String _role;
  final LocalDb _db;

  String? _draftKey;

  static const _prefSkipAutoEdit = 'presupuesto_skip_auto_edit_dialog';

  QuotationBuilderController({
    required QuotationApi api,
    required String role,
    required LocalDb db,
  }) : _api = api,
       _role = role,
       _db = db,
       super(QuotationBuilderState.initial()) {
    _ensureAtLeastOneTicket();
    _loadPrefs();
    _bootstrapDraft();
  }

  bool get canSeeCost => _role == 'admin' || _role == 'administrador';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_prefSkipAutoEdit) ?? false;
    state = state.copyWith(skipAutoEditDialog: skip, clearError: true);
  }

  Future<void> _bootstrapDraft() async {
    try {
      final session = await _db.readSession();
      if (session == null) return;
      _draftKey = 'presupuesto:${session.user.empresaId}:${session.user.id}';

      final jsonStr = await _db.loadPresupuestoDraftJson(draftKey: _draftKey!);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        // Ensure there is always a local draft container to restore later.
        await _persistDraft();
        return;
      }

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = _decodeDraft(map);
      state = restored.copyWith(
        skipAutoEditDialog: state.skipAutoEditDialog,
        clearError: true,
      );
    } catch (_) {
      // If draft is corrupt, ignore and keep initial state.
    }
  }

  Future<void> _persistDraft() async {
    final key = _draftKey;
    if (key == null) return;
    final jsonStr = jsonEncode(_encodeDraft(state));
    await _db.savePresupuestoDraft(draftKey: key, draftJson: jsonStr);
  }

  Map<String, dynamic> _encodeDraft(QuotationBuilderState s) {
    return {
      'v': 2,
      'active_ticket': s.activeTicketIndex,
      'tickets': s.tickets
          .map(
            (t) => {
              'id': t.id,
              'name': t.name,
              'quotation_id': t.quotationId,
              'remote_created': t.remoteCreated,
              'customer': t.customer == null
                  ? null
                  : {
                      'id': t.customer!.id,
                      'nombre': t.customer!.nombre,
                      'telefono': t.customer!.telefono,
                      'email': t.customer!.email,
                    },
              'items': t.items
                  .map((it) => it.toDraftJson())
                  .toList(growable: false),
              'itbis_enabled': t.itbisEnabled,
              'itbis_rate': t.itbisRate,
            },
          )
          .toList(growable: false),
    };
  }

  QuotationBuilderState _decodeDraft(Map<String, dynamic> json) {
    // v2: multi-ticket
    final ticketsJson = json['tickets'];
    if (ticketsJson is List) {
      final tickets = <QuotationTicketDraft>[];
      for (final raw in ticketsJson) {
        if (raw is! Map) continue;
        final id = (raw['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final name = (raw['name'] ?? '').toString().trim();

        final quotationId = raw['quotation_id']?.toString();
        final remoteCreated = (raw['remote_created'] as bool?) ?? false;

        QuotationCustomerDraft? customer;
        final customerJson = raw['customer'];
        if (customerJson is Map) {
          customer = QuotationCustomerDraft(
            id: customerJson['id']?.toString(),
            nombre: (customerJson['nombre'] ?? '').toString(),
            telefono: customerJson['telefono']?.toString(),
            email: customerJson['email']?.toString(),
          );
        }

        final items = <QuotationItemDraft>[];
        final itemsJson = raw['items'];
        if (itemsJson is List) {
          for (final itRaw in itemsJson) {
            if (itRaw is! Map) continue;
            final localId = (itRaw['local_id'] ?? '').toString();
            if (localId.isEmpty) continue;
            items.add(
              QuotationItemDraft.fromDraftJson(
                Map<String, dynamic>.from(itRaw),
              ),
            );
          }
        }

        tickets.add(
          QuotationTicketDraft(
            id: id,
            name: name.isEmpty ? 'Ticket ${tickets.length + 1}' : name,
            quotationId: quotationId,
            remoteCreated: remoteCreated,
            customer: customer,
            items: items,
            itbisEnabled: (raw['itbis_enabled'] as bool?) ?? true,
            itbisRate: (raw['itbis_rate'] as num?)?.toDouble() ?? 0.18,
          ),
        );
      }

      final active = (json['active_ticket'] as num?)?.toInt() ?? 0;
      final ensured = tickets.isEmpty
          ? [QuotationTicketDraft.initial(id: _newTicketId(), name: 'Ticket 1')]
          : tickets;

      return QuotationBuilderState(
        isSaving: false,
        error: null,
        tickets: ensured,
        activeTicketIndex: active.clamp(0, ensured.length - 1),
        skipAutoEditDialog: state.skipAutoEditDialog,
      );
    }

    // v1 compatibility: single-ticket (customer/items/itbis_*)
    QuotationCustomerDraft? customer;
    final customerJson = json['customer'];
    if (customerJson is Map) {
      customer = QuotationCustomerDraft(
        id: customerJson['id']?.toString(),
        nombre: (customerJson['nombre'] ?? '').toString(),
        telefono: customerJson['telefono']?.toString(),
        email: customerJson['email']?.toString(),
      );
    }

    final items = <QuotationItemDraft>[];
    final itemsJson = json['items'];
    if (itemsJson is List) {
      for (final raw in itemsJson) {
        if (raw is! Map) continue;
        final localId = (raw['local_id'] ?? '').toString();
        if (localId.isEmpty) continue;
        items.add(
          QuotationItemDraft.fromDraftJson(Map<String, dynamic>.from(raw)),
        );
      }
    }

    final t = QuotationTicketDraft(
      id: _newTicketId(),
      name: 'Ticket 1',
      quotationId: null,
      remoteCreated: false,
      customer: customer,
      items: items,
      itbisEnabled: (json['itbis_enabled'] as bool?) ?? true,
      itbisRate: (json['itbis_rate'] as num?)?.toDouble() ?? 0.18,
    );

    return QuotationBuilderState(
      isSaving: false,
      error: null,
      tickets: [t],
      activeTicketIndex: 0,
      skipAutoEditDialog: state.skipAutoEditDialog,
    );
  }

  String _newTicketId() {
    final r = Random().nextInt(1 << 32);
    return 't-${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  void _ensureAtLeastOneTicket() {
    if (state.tickets.isNotEmpty) return;
    state = state.copyWith(
      tickets: [
        QuotationTicketDraft.initial(id: _newTicketId(), name: 'Ticket 1'),
      ],
      activeTicketIndex: 0,
      clearError: true,
    );
  }

  void selectTicket(int index) {
    _ensureAtLeastOneTicket();
    final nextIndex = index.clamp(0, state.tickets.length - 1);
    state = state.copyWith(activeTicketIndex: nextIndex, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  void addTicket() {
    _ensureAtLeastOneTicket();
    final next = [...state.tickets];
    final name = 'Ticket ${next.length + 1}';
    next.add(QuotationTicketDraft.initial(id: _newTicketId(), name: name));
    state = state.copyWith(
      tickets: next,
      activeTicketIndex: next.length - 1,
      clearError: true,
    );
    // ignore: unawaited_futures
    _persistDraft();
  }

  void renameTicket(int index, String name) {
    _ensureAtLeastOneTicket();
    final idx = index.clamp(0, state.tickets.length - 1);
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = [...state.tickets];
    next[idx] = next[idx].copyWith(name: trimmed);
    state = state.copyWith(tickets: next, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  Future<void> setSkipAutoEditDialog(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSkipAutoEdit, value);
    state = state.copyWith(skipAutoEditDialog: value, clearError: true);
  }

  void setCustomer(QuotationCustomerDraft? customer) {
    _ensureAtLeastOneTicket();
    final idx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final next = [...state.tickets];
    final current = next[idx];
    var updated = current.copyWith(customer: customer);

    // Auto-name ticket with customer name if it's still the default "Ticket N".
    final defaultName = RegExp(r'^Ticket\s+\d+$', caseSensitive: false);
    if (customer != null && defaultName.hasMatch(updated.name.trim())) {
      final n = customer.nombre.trim();
      if (n.isNotEmpty) {
        updated = updated.copyWith(name: n);
      }
    }

    next[idx] = updated;
    state = state.copyWith(tickets: next, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  void setItbisEnabled(bool value) {
    _ensureAtLeastOneTicket();
    final idx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final next = [...state.tickets];
    next[idx] = next[idx].copyWith(itbisEnabled: value);
    state = state.copyWith(tickets: next, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  void setItbisRate(double value) {
    _ensureAtLeastOneTicket();
    final idx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final next = [...state.tickets];
    next[idx] = next[idx].copyWith(itbisRate: value);
    state = state.copyWith(tickets: next, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  String _newLocalId() {
    final r = Random().nextInt(1 << 32);
    return 'qi-${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  /// Returns the added item localId.
  String addProduct({
    required String productId,
    required String nombre,
    required double unitPrice,
    double? unitCost,
  }) {
    _ensureAtLeastOneTicket();
    final tIdx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final ticket = state.tickets[tIdx];
    final existingIndex = ticket.items.indexWhere(
      (it) => it.productId == productId,
    );
    if (existingIndex >= 0) {
      final existing = ticket.items[existingIndex];
      final updated = existing.copyWith(cantidad: existing.cantidad + 1);
      final nextItems = [...ticket.items]..[existingIndex] = updated;
      final nextTickets = [...state.tickets];
      nextTickets[tIdx] = ticket.copyWith(items: nextItems);
      state = state.copyWith(tickets: nextTickets, clearError: true);
      // ignore: unawaited_futures
      _persistDraft();
      return existing.localId;
    }

    final item = QuotationItemDraft(
      localId: _newLocalId(),
      productId: productId,
      nombre: nombre,
      cantidad: 1,
      unitPrice: unitPrice,
      unitCost: unitCost,
      discountPct: 0,
      discountAmount: 0,
      discountMode: QuotationDiscountMode.percent,
    );

    final nextTickets = [...state.tickets];
    nextTickets[tIdx] = ticket.copyWith(items: [...ticket.items, item]);
    state = state.copyWith(tickets: nextTickets, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
    return item.localId;
  }

  String addManualItem({
    required String nombre,
    required double unitPrice,
    double? unitCost,
  }) {
    _ensureAtLeastOneTicket();
    final tIdx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final ticket = state.tickets[tIdx];
    final item = QuotationItemDraft(
      localId: _newLocalId(),
      productId: null,
      nombre: nombre,
      cantidad: 1,
      unitPrice: unitPrice,
      unitCost: unitCost,
      discountPct: 0,
      discountAmount: 0,
      discountMode: QuotationDiscountMode.percent,
    );

    final nextTickets = [...state.tickets];
    nextTickets[tIdx] = ticket.copyWith(items: [...ticket.items, item]);
    state = state.copyWith(tickets: nextTickets, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
    return item.localId;
  }

  void updateItem(String localId, QuotationItemDraft nextItem) {
    _ensureAtLeastOneTicket();
    final tIdx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final ticket = state.tickets[tIdx];
    final idx = ticket.items.indexWhere((it) => it.localId == localId);
    if (idx < 0) return;
    final nextItems = [...ticket.items]..[idx] = nextItem;
    final nextTickets = [...state.tickets];
    nextTickets[tIdx] = ticket.copyWith(items: nextItems);
    state = state.copyWith(tickets: nextTickets, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  void removeItem(String localId) {
    _ensureAtLeastOneTicket();
    final tIdx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final ticket = state.tickets[tIdx];
    final nextItems = ticket.items
        .where((it) => it.localId != localId)
        .toList();
    final nextTickets = [...state.tickets];
    nextTickets[tIdx] = ticket.copyWith(items: nextItems);
    state = state.copyWith(tickets: nextTickets, clearError: true);
    // ignore: unawaited_futures
    _persistDraft();
  }

  Future<Map<String, dynamic>?> saveQuotation({String? notes}) async {
    _ensureAtLeastOneTicket();
    if (state.customer == null || state.customer!.nombre.trim().isEmpty) {
      state = state.copyWith(error: 'Selecciona un cliente', isSaving: false);
      return null;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Agrega al menos un item', isSaving: false);
      return null;
    }

    final session = await _db.readSession();
    if (session == null) {
      state = state.copyWith(
        error: 'Sesion no valida. Inicia sesion de nuevo.',
        isSaving: false,
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final tIdx = state.activeTicketIndex.clamp(0, state.tickets.length - 1);
    final active = state.tickets[tIdx];

    final uuid = const Uuid();
    final localId = (active.quotationId == null || active.quotationId!.isEmpty)
        ? uuid.v4()
        : active.quotationId!;

    if (active.quotationId != localId) {
      final nextTickets = [...state.tickets];
      nextTickets[tIdx] = active.copyWith(quotationId: localId);
      state = state.copyWith(tickets: nextTickets, clearError: true);
      // ignore: unawaited_futures
      _persistDraft();
    }

    final nowIso = DateTime.now().toIso8601String();

    bool isNetworkError(Object e) {
      if (e is DioException) {
        return e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
      }
      final msg = e.toString();
      return msg.contains('SocketException') || msg.contains('Failed host lookup');
    }

    try {
      // 1) Always persist locally first.
      await _db.upsertCotizacion(
        row: {
          'id': localId,
          'empresa_id': session.user.empresaId,
          'numero': null,
          'customer_id': state.customer!.id,
          'customer_name': state.customer!.nombre,
          'customer_phone': state.customer!.telefono,
          'customer_email': state.customer!.email,
          'itbis_enabled': state.itbisEnabled ? 1 : 0,
          'itbis_rate': state.itbisRate,
          'subtotal': state.subtotal,
          'itbis_amount': state.itbisAmount,
          'total': state.total,
          'notes': (notes != null && notes.trim().isNotEmpty)
              ? notes.trim()
              : null,
          'status': 'draft',
          'created_by_user_id': session.user.id,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sync_status': 'pending',
        },
      );

      await _db.replaceCotizacionItems(
        quotationId: localId,
        items: state.items
            .map(
              (it) => <String, Object?>{
                'id': it.localId,
                'quotation_id': localId,
                'product_id': it.productId,
                'nombre': it.nombre,
                'cantidad': it.cantidad,
                'unit_cost': (it.unitCost ?? 0.0),
                'unit_price': it.unitPrice,
                'discount_pct': it.discountPct,
                'discount_amount': it.discountAmount,
                'line_subtotal': it.lineNet,
                'line_total': it.lineNet,
                'created_at': nowIso,
              },
            )
            .toList(growable: false),
      );

      Map<String, dynamic> localRow =
          (await _db.getCotizacion(id: localId))?.cast<String, dynamic>() ??
          <String, dynamic>{'id': localId, 'sync_status': 'pending'};

      // 2) Best-effort remote sync.
      final payload = {
        // Attempt to keep a stable UUID across offline-first creates.
        'id': localId,
        'customer_id': state.customer!.id,
        'customer_name': state.customer!.nombre,
        if (state.customer!.telefono != null)
          'customer_phone': state.customer!.telefono,
        if (state.customer!.email != null)
          'customer_email': state.customer!.email,
        'itbis_enabled': state.itbisEnabled,
        'itbis_rate': state.itbisRate,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'items': state.items.map((it) => it.toCreateJson()).toList(),
      };

      Map<String, dynamic>? remote;
      try {
        if (active.remoteCreated) {
          remote = await _api.updateQuotation(localId, payload);
        } else {
          try {
            remote = await _api.createQuotation(payload);
          } catch (_) {
            // If server doesn't accept client-supplied id, or it already exists,
            // attempt an update as a fallback.
            remote = await _api.updateQuotation(localId, payload);
          }
        }
      } catch (e) {
        if (isNetworkError(e)) {
          // Offline: enqueue and return the local pending record.
          await _db.enqueueSync(
            module: 'quotations',
            op: 'upsert',
            entityId: localId,
            payloadJson: jsonEncode(payload),
          );
          state = state.copyWith(isSaving: false, clearError: true);
          return localRow;
        }
        rethrow;
      }

      final remoteId = (remote['id'] ?? localId).toString();

      // If server returns a different id, migrate local rows.
      if (remoteId.isNotEmpty && remoteId != localId) {
        await _db.upsertCotizacion(
          row: {
            'id': remoteId,
            'empresa_id': session.user.empresaId,
            'numero': (remote['numero'] ?? '').toString(),
            'customer_id':
                (remote['customerId'] ??
                        remote['customer_id'] ??
                        state.customer!.id)
                    ?.toString(),
            'customer_name':
                (remote['customerName'] ??
                        remote['customer_name'] ??
                        state.customer!.nombre)
                    .toString(),
            'customer_phone':
                (remote['customerPhone'] ??
                        remote['customer_phone'] ??
                        state.customer!.telefono)
                    ?.toString(),
            'customer_email':
                (remote['customerEmail'] ??
                        remote['customer_email'] ??
                        state.customer!.email)
                    ?.toString(),
            'itbis_enabled':
                ((remote['itbisEnabled'] ?? remote['itbis_enabled']) == true)
                ? 1
                : (state.itbisEnabled ? 1 : 0),
            'itbis_rate':
                (remote['itbisRate'] ?? remote['itbis_rate'] as num?)
                    ?.toDouble() ??
                state.itbisRate,
            'subtotal':
                (remote['subtotal'] as num?)?.toDouble() ?? state.subtotal,
            'itbis_amount':
                (remote['itbisAmount'] ?? remote['itbis_amount'] as num?)
                    ?.toDouble() ??
                state.itbisAmount,
            'total': (remote['total'] as num?)?.toDouble() ?? state.total,
            'notes':
                remote['notes'] ??
                ((notes != null && notes.trim().isNotEmpty)
                    ? notes.trim()
                    : null),
            'status': (remote['status'] ?? 'draft').toString(),
            'created_by_user_id':
                (remote['createdByUserId'] ??
                        remote['created_by_user_id'] ??
                        session.user.id)
                    .toString(),
            'created_at':
                (remote['createdAt'] ?? remote['created_at'] ?? nowIso)
                    .toString(),
            'updated_at':
                (remote['updatedAt'] ?? remote['updated_at'] ?? nowIso)
                    .toString(),
            'sync_status': 'synced',
          },
        );

        final remoteItems =
            (remote['items'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
        if (remoteItems.isNotEmpty) {
          await _db.replaceCotizacionItems(
            quotationId: remoteId,
            items: remoteItems
                .map(
                  (it) => <String, Object?>{
                    'id': (it['id'] ?? uuid.v4()).toString(),
                    'quotation_id': remoteId,
                    'product_id': it['productId'] ?? it['product_id'],
                    'nombre': (it['nombre'] ?? it['name'] ?? '').toString(),
                    'cantidad':
                        (it['cantidad'] as num?)?.toDouble() ??
                        (it['quantity'] as num?)?.toDouble() ??
                        1.0,
                    'unit_cost':
                        (it['unitCost'] as num?)?.toDouble() ??
                        (it['unit_cost'] as num?)?.toDouble() ??
                        0.0,
                    'unit_price':
                        (it['unitPrice'] as num?)?.toDouble() ??
                        (it['unit_price'] as num?)?.toDouble() ??
                        0.0,
                    'discount_pct':
                        (it['discountPct'] as num?)?.toDouble() ??
                        (it['discount_pct'] as num?)?.toDouble() ??
                        0.0,
                    'discount_amount':
                        (it['discountAmount'] as num?)?.toDouble() ??
                        (it['discount_amount'] as num?)?.toDouble() ??
                        0.0,
                    'line_subtotal':
                        (it['lineSubtotal'] as num?)?.toDouble() ??
                        (it['line_subtotal'] as num?)?.toDouble() ??
                        0.0,
                    'line_total':
                        (it['lineTotal'] as num?)?.toDouble() ??
                        (it['line_total'] as num?)?.toDouble() ??
                        0.0,
                    'created_at':
                        (it['createdAt'] ?? it['created_at'] ?? nowIso)
                            .toString(),
                  },
                )
                .toList(growable: false),
          );
        } else {
          // Keep local item snapshot if server doesn't return items.
          final localItems = await _db.listCotizacionItems(
            quotationId: localId,
          );
          await _db.replaceCotizacionItems(
            quotationId: remoteId,
            items: localItems
                .map((e) => <String, Object?>{...e, 'quotation_id': remoteId})
                .toList(growable: false),
          );
        }

        await _db.deleteCotizacion(id: localId);
        localRow =
            (await _db.getCotizacion(id: remoteId))?.cast<String, dynamic>() ??
            remote;

        final nextTickets = [...state.tickets];
        nextTickets[tIdx] = nextTickets[tIdx].copyWith(
          quotationId: remoteId,
          remoteCreated: true,
        );
        state = state.copyWith(tickets: nextTickets, clearError: true);
        // ignore: unawaited_futures
        _persistDraft();
      } else {
        // Normal case: same id.
        await _db.upsertCotizacion(
          row: {
            'id': localId,
            'empresa_id': session.user.empresaId,
            'numero': (remote['numero'] ?? '').toString(),
            'customer_id':
                (remote['customerId'] ??
                        remote['customer_id'] ??
                        state.customer!.id)
                    ?.toString(),
            'customer_name':
                (remote['customerName'] ??
                        remote['customer_name'] ??
                        state.customer!.nombre)
                    .toString(),
            'customer_phone':
                (remote['customerPhone'] ??
                        remote['customer_phone'] ??
                        state.customer!.telefono)
                    ?.toString(),
            'customer_email':
                (remote['customerEmail'] ??
                        remote['customer_email'] ??
                        state.customer!.email)
                    ?.toString(),
            'itbis_enabled':
                ((remote['itbisEnabled'] ?? remote['itbis_enabled']) == true)
                ? 1
                : (state.itbisEnabled ? 1 : 0),
            'itbis_rate':
                (remote['itbisRate'] ?? remote['itbis_rate'] as num?)
                    ?.toDouble() ??
                state.itbisRate,
            'subtotal':
                (remote['subtotal'] as num?)?.toDouble() ?? state.subtotal,
            'itbis_amount':
                (remote['itbisAmount'] ?? remote['itbis_amount'] as num?)
                    ?.toDouble() ??
                state.itbisAmount,
            'total': (remote['total'] as num?)?.toDouble() ?? state.total,
            'notes':
                remote['notes'] ??
                ((notes != null && notes.trim().isNotEmpty)
                    ? notes.trim()
                    : null),
            'status': (remote['status'] ?? 'draft').toString(),
            'created_by_user_id':
                (remote['createdByUserId'] ??
                        remote['created_by_user_id'] ??
                        session.user.id)
                    .toString(),
            'created_at':
                (remote['createdAt'] ?? remote['created_at'] ?? nowIso)
                    .toString(),
            'updated_at':
                (remote['updatedAt'] ?? remote['updated_at'] ?? nowIso)
                    .toString(),
            'sync_status': 'synced',
          },
        );

        localRow =
            (await _db.getCotizacion(id: localId))?.cast<String, dynamic>() ??
            remote;

        final nextTickets = [...state.tickets];
        nextTickets[tIdx] = nextTickets[tIdx].copyWith(remoteCreated: true);
        state = state.copyWith(tickets: nextTickets, clearError: true);
        // ignore: unawaited_futures
        _persistDraft();
      }

      state = state.copyWith(isSaving: false, clearError: true);
      return localRow;
    } catch (e) {
      // Local save already happened; keep it as pending.
      state = state.copyWith(isSaving: false, clearError: true);
      final existing = await _db.getCotizacion(id: localId);
      return existing?.cast<String, dynamic>() ??
          <String, dynamic>{'id': localId, 'sync_status': 'pending'};
    }
  }
}
