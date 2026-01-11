import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarrantyOption {
  final String id;
  final String name;

  const WarrantyOption({required this.id, required this.name});

  WarrantyOption copyWith({String? id, String? name}) {
    return WarrantyOption(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static WarrantyOption fromJson(Map<String, dynamic> json) {
    return WarrantyOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class WarrantyOptionsController extends StateNotifier<List<WarrantyOption>> {
  WarrantyOptionsController() : super(const []) {
    _load();
  }

  static const _key = 'settings.pos.warrantyOptions.v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_key) ?? '').trim();
    if (raw.isEmpty) {
      state = const [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      final list = (decoded as List?)?.cast<dynamic>() ?? const [];
      state = list
          .whereType<Map>()
          .map((e) => WarrantyOption.fromJson(e.cast<String, dynamic>()))
          .where((o) => o.id.trim().isNotEmpty && o.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _persist(List<WarrantyOption> next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(next.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> addOption(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final id = 'warranty-${DateTime.now().microsecondsSinceEpoch}';
    await _persist([...state, WarrantyOption(id: id, name: trimmed)]);
  }

  Future<void> renameOption({required String id, required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final next = state
        .map((o) => o.id == id ? o.copyWith(name: trimmed) : o)
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> removeOption(String id) async {
    final next = state.where((o) => o.id != id).toList(growable: false);
    await _persist(next);
  }
}

final warrantyOptionsProvider =
    StateNotifierProvider<WarrantyOptionsController, List<WarrantyOption>>((ref) {
      return WarrantyOptionsController();
    });
