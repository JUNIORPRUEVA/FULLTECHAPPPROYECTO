import 'package:dio/dio.dart';

class PermissionCatalogItem {
  final String code;
  final String description;

  const PermissionCatalogItem({required this.code, required this.description});
}

class RbacRoleItem {
  final String id;
  final String name;

  const RbacRoleItem({required this.id, required this.name});
}

class UserPermissionOverride {
  final String code;
  final String effect; // allow|deny

  const UserPermissionOverride({required this.code, required this.effect});
}

class UserPermissionsItem {
  final String id;
  final String name;
  final String email;
  final String legacyRole;
  final String estado;
  final List<RbacRoleItem> roles;
  final List<UserPermissionOverride> overrides;
  final List<String> effectivePermissions;

  const UserPermissionsItem({
    required this.id,
    required this.name,
    required this.email,
    required this.legacyRole,
    required this.estado,
    required this.roles,
    required this.overrides,
    required this.effectivePermissions,
  });
}

class PermissionsSettingsRepository {
  final Dio dio;

  PermissionsSettingsRepository(this.dio);

  Future<List<PermissionCatalogItem>> getCatalog() async {
    final res = await dio.get(
      '/settings/permissions/catalog',
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).cast<dynamic>();
    return items
        .map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return PermissionCatalogItem(
            code: m['code'].toString(),
            description: m['description'].toString(),
          );
        })
        .toList();
  }

  Future<List<RbacRoleItem>> getRoles() async {
    final res = await dio.get(
      '/settings/permissions/roles',
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).cast<dynamic>();
    return items
        .map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return RbacRoleItem(id: m['id'].toString(), name: m['name'].toString());
        })
        .toList();
  }

  Future<List<UserPermissionsItem>> getUsers() async {
    final res = await dio.get(
      '/settings/permissions/users',
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).cast<dynamic>();
    return items.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final roles = ((m['roles'] as List?) ?? const [])
          .map((r) {
            final rm = (r as Map).cast<String, dynamic>();
            return RbacRoleItem(id: rm['id'].toString(), name: rm['name'].toString());
          })
          .toList();
      final overrides = ((m['overrides'] as List?) ?? const [])
          .map((o) {
            final om = (o as Map).cast<String, dynamic>();
            return UserPermissionOverride(code: om['code'].toString(), effect: om['effect'].toString());
          })
          .toList();
      final eff = ((m['effectivePermissions'] as List?) ?? const [])
          .map((p) => p.toString())
          .toList();

      return UserPermissionsItem(
        id: m['id'].toString(),
        name: m['name'].toString(),
        email: m['email'].toString(),
        legacyRole: m['legacyRole'].toString(),
        estado: m['estado'].toString(),
        roles: roles,
        overrides: overrides,
        effectivePermissions: eff,
      );
    }).toList();
  }

  Future<void> updateUser({
    required String userId,
    required List<String> roleIds,
    required List<UserPermissionOverride> overrides,
  }) async {
    await dio.put(
      '/settings/permissions/users/$userId',
      data: {
        'roleIds': roleIds,
        'overrides': overrides
            .map((o) => {
                  'code': o.code,
                  'effect': o.effect,
                })
            .toList(),
      },
      options: Options(extra: {'offlineCache': false, 'offlineQueue': false}),
    );
  }
}
