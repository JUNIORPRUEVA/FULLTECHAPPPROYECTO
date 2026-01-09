import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/app_config.dart';
import '../../../../core/widgets/module_page.dart';
import '../../data/models/user_model.dart';
import '../../state/users_providers.dart';
import '../widgets/document_preview.dart';

class UserFormPage extends ConsumerStatefulWidget {
  final String? userId;

  const UserFormPage({super.key, this.userId});

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _lugarNacimientoCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  final _beneficioNombreCtrl = TextEditingController();
  final _beneficioMontoCtrl = TextEditingController();
  final _licenciaConducirNumeroCtrl = TextEditingController();
  final _tipoVehiculoCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _areaManejadaCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  final _areaTrabajoCrtlr = TextEditingController();
  final _horarioDisponibleCtrl = TextEditingController();
  final _metaVentasCtrl = TextEditingController();
  final _ultimoTrabajoCtrl = TextEditingController();
  final _motivoSalidaCtrl = TextEditingController();

  final List<Map<String, dynamic>> _beneficios = [];
  final List<String> _especialidades = [];
  final List<String> _areasTrabajo = [];

  String _rol = 'vendedor';
  String _tipoBeneficio = 'monto'; // 'monto' o 'porcentaje'
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;
  DateTime? _licenciaVencimiento;

  bool _esCasado = false;
  int _cantidadHijos = 0;
  bool _tieneCasa = false;
  bool _tieneVehiculo = false;

  _PickedDoc? _fotoPerfil;
  _PickedDoc? _cedulaFrontal;
  _PickedDoc? _cedulaPosterior;
  _PickedDoc? _licenciaConducir;
  _PickedDoc? _cartaTrabajo;
  _PickedDoc? _curriculumVitae;
  final List<_PickedDoc> _otrosDocumentos = [];

  bool _saving = false;
  bool _readingCedula = false;
  bool _readingLicencia = false;
  UserModel? _editingUser;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      Future.microtask(() async {
        final user = await ref
            .read(usersRepositoryProvider)
            .getUser(widget.userId!);
        if (!mounted) return;
        setState(() {
          _editingUser = user;
          _populate(user);
        });
      });
    }
  }

  void _populate(UserModel u) {
    _nombreCtrl.text = u.nombre;
    _emailCtrl.text = u.email;
    _rol = u.rol;
    _telefonoCtrl.text = u.telefono ?? '';
    _direccionCtrl.text = u.direccion ?? '';
    _ubicacionCtrl.text = u.ubicacionMapa ?? '';
    _cedulaCtrl.text = u.cedulaNumero ?? '';
    _lugarNacimientoCtrl.text = u.lugarNacimiento ?? '';
    _fechaNacimiento = u.fechaNacimiento;
    _fechaIngreso = u.fechaIngreso;

    _esCasado = u.esCasado;
    _cantidadHijos = u.cantidadHijos;
    _tieneCasa = u.tieneCasa;
    _tieneVehiculo = u.tieneVehiculo;
    _tipoVehiculoCtrl.text = u.tipoVehiculo ?? '';
    _placaCtrl.text = u.placa ?? '';

    _salarioCtrl.text = (u.salarioMensual ?? '').toString();
    if (u.beneficios != null) {
      try {
        _beneficios.addAll(
          List<Map<String, dynamic>>.from(
            (u.beneficios is String ? [] : u.beneficios) as List? ?? [],
          ),
        );
      } catch (_) {
        // Si no es una lista válida, ignorar
      }
    }

    _licenciaConducirNumeroCtrl.text = u.licenciaConducirNumero ?? '';
    _licenciaVencimiento = u.licenciaConducirVencimiento;
  }

  void _addBeneficio() {
    final nombre = _beneficioNombreCtrl.text.trim();
    final monto = num.tryParse(_beneficioMontoCtrl.text.trim());

    if (nombre.isEmpty || monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa nombre y monto válido para el beneficio.'),
        ),
      );
      return;
    }

    setState(() {
      _beneficios.add({
        'nombre': nombre,
        'monto': monto,
        'tipo': _tipoBeneficio,
      });
      _beneficioNombreCtrl.clear();
      _beneficioMontoCtrl.clear();
    });
  }

  void _removeBeneficio(int index) {
    setState(() => _beneficios.removeAt(index));
  }

  void _addEspecialidad() {
    final especialidad = _especialidadCtrl.text.trim();
    if (especialidad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una especialidad.')),
      );
      return;
    }

    setState(() {
      _especialidades.add(especialidad);
      _especialidadCtrl.clear();
    });
  }

  void _removeEspecialidad(int index) {
    setState(() => _especialidades.removeAt(index));
  }

  void _addAreaTrabajo() {
    final area = _areaTrabajoCrtlr.text.trim();
    if (area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un área de trabajo.')),
      );
      return;
    }

    setState(() {
      _areasTrabajo.add(area);
      _areaTrabajoCrtlr.clear();
    });
  }

  void _removeAreaTrabajo(int index) {
    setState(() => _areasTrabajo.removeAt(index));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _cedulaCtrl.dispose();
    _lugarNacimientoCtrl.dispose();
    _salarioCtrl.dispose();
    _beneficioNombreCtrl.dispose();
    _beneficioMontoCtrl.dispose();
    _licenciaConducirNumeroCtrl.dispose();
    _tipoVehiculoCtrl.dispose();
    _placaCtrl.dispose();
    _areaManejadaCtrl.dispose();
    _especialidadCtrl.dispose();
    _areaTrabajoCrtlr.dispose();
    _horarioDisponibleCtrl.dispose();
    _metaVentasCtrl.dispose();
    super.dispose();
  }

  static String _publicBase() {
    final base = AppConfig.apiBaseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String? _resolvePublicUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '${_publicBase()}$trimmed';
    return '${_publicBase()}/$trimmed';
  }

  Future<_PickedDoc?> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return null;
    if (f.bytes == null && (f.path == null || f.path!.trim().isEmpty)) {
      return null;
    }
    return _PickedDoc(path: f.path, bytes: f.bytes);
  }

  Future<void> _pickAndSetSingle(void Function(_PickedDoc?) assign) async {
    final picked = await _pickImage();
    if (!mounted) return;
    setState(() => assign(picked));
  }

  MultipartFile _toMultipart(_PickedDoc doc) {
    if (doc.bytes != null) {
      return MultipartFile.fromBytes(doc.bytes!, filename: 'documento.jpg');
    }
    return MultipartFile.fromFileSync(doc.path!);
  }

  Future<Map<String, dynamic>> _uploadDocsIfNeeded() async {
    final hasAny =
        _fotoPerfil != null ||
        _cedulaFrontal != null ||
        _cedulaPosterior != null ||
        _licenciaConducir != null ||
        _cartaTrabajo != null ||
        _curriculumVitae != null ||
        _otrosDocumentos.isNotEmpty;
    if (!hasAny) return {};

    return ref
        .read(usersRepositoryProvider)
        .uploadUserDocuments(
          fotoPerfil: _fotoPerfil != null ? _toMultipart(_fotoPerfil!) : null,
          cedulaFrontal: _cedulaFrontal != null
              ? _toMultipart(_cedulaFrontal!)
              : null,
          cedulaPosterior: _cedulaPosterior != null
              ? _toMultipart(_cedulaPosterior!)
              : null,
          licenciaConducir: _licenciaConducir != null
              ? _toMultipart(_licenciaConducir!)
              : null,
          cartaTrabajo: _cartaTrabajo != null
              ? _toMultipart(_cartaTrabajo!)
              : null,
          curriculumVitae: _curriculumVitae != null
              ? _toMultipart(_curriculumVitae!)
              : null,
          otrosDocumentos: _otrosDocumentos
              .map(_toMultipart)
              .toList(growable: false),
        );
  }

  static DateTime? _tryParseDateOnly(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      // Expects YYYY-MM-DD
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<void> _autoFillFromCedula() async {
    final doc = _cedulaFrontal;
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona la imagen de la cédula frontal.'),
        ),
      );
      return;
    }

    setState(() => _readingCedula = true);
    try {
      final res = await ref
          .read(usersRepositoryProvider)
          .extractFromCedula(cedulaFrontal: _toMultipart(doc));

      final extracted = (res['extracted'] is Map)
          ? (res['extracted'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

      final nombre = extracted['nombre_completo'] as String?;
      final cedula = extracted['cedula_numero'] as String?;
      final lugar = extracted['lugar_nacimiento'] as String?;
      final fechaStr = extracted['fecha_nacimiento'] as String?;
      final fecha = _tryParseDateOnly(fechaStr);

      setState(() {
        if (nombre != null && nombre.trim().isNotEmpty) {
          _nombreCtrl.text = nombre.trim();
        }
        if (cedula != null && cedula.trim().isNotEmpty) {
          _cedulaCtrl.text = cedula.trim();
        }
        if (lugar != null && lugar.trim().isNotEmpty) {
          _lugarNacimientoCtrl.text = lugar.trim();
        }
        if (fecha != null) _fechaNacimiento = fecha;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos leídos de la cédula. Verifica y corrige si es necesario.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _readingCedula = false);
    }
  }

  Future<void> _autoFillFromLicencia() async {
    final doc = _licenciaConducir;
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero selecciona la imagen de la licencia de conducir.',
          ),
        ),
      );
      return;
    }

    setState(() => _readingLicencia = true);
    try {
      final res = await ref
          .read(usersRepositoryProvider)
          .extractFromLicencia(licenciaFrontal: _toMultipart(doc));

      final extracted = (res['extracted'] is Map)
          ? (res['extracted'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

      final numero = extracted['numero_licencia'] as String?;
      final fechaStr = extracted['fecha_vencimiento'] as String?;
      final fecha = _tryParseDateOnly(fechaStr);

      setState(() {
        if (numero != null && numero.trim().isNotEmpty) {
          _licenciaConducirNumeroCtrl.text = numero.trim();
        }
        if (fecha != null) _licenciaVencimiento = fecha;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos leídos de la licencia. Verifica y corrige si es necesario.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _readingLicencia = false);
    }
  }

  Future<void> _fillGpsLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el servicio de ubicación del dispositivo.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final url =
          'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}';

      if (!mounted) return;
      setState(() => _ubicacionCtrl.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación capturada.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validaciones condicionales según el rol
    if (_rol == 'tecnico_fijo') {
      if (_areaManejadaCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa el área que maneja.')),
        );
        return;
      }
      if (_especialidades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos una especialidad.')),
        );
        return;
      }
    }
    if (_rol == 'contratista') {
      if (_areasTrabajo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos un área de trabajo.')),
        );
        return;
      }
    } else if (_rol != 'tecnico_fijo' && _rol != 'contratista') {
      if (_fechaNacimiento == null || _fechaIngreso == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa las fechas requeridas.')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final docs = await _uploadDocsIfNeeded();

      final isContratista = _rol == 'contratista';
      final isNew = widget.userId == null;

      final payload = <String, dynamic>{
        'nombre_completo': _nombreCtrl.text.trim(),
        'rol': _rol,
        'cedula_numero': _cedulaCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
      };

      // Credenciales solo para usuarios que inician sesión
      if (!isContratista) {
        payload['email'] = _emailCtrl.text.trim();
        if (isNew) {
          payload['password'] = _passwordCtrl.text;
        }
      }

      // Campos condicionales según el rol
      if (_rol == 'contratista') {
        payload['areas_trabajo'] = _areasTrabajo;
        if (_beneficios.isNotEmpty) {
          payload['beneficios'] = _beneficios;
        }
        final horario = _horarioDisponibleCtrl.text.trim();
        if (horario.isNotEmpty) {
          payload['horario_disponible'] = horario;
        }
      } else if (_rol == 'tecnico_fijo') {
        payload['area_maneja'] = _areaManejadaCtrl.text.trim();
        payload['especialidades'] = _especialidades;
        payload['licencia_conducir_numero'] =
            _licenciaConducirNumeroCtrl.text.trim().isEmpty
            ? null
            : _licenciaConducirNumeroCtrl.text.trim();
        payload['licencia_conducir_fecha_vencimiento'] = _licenciaVencimiento;
      } else {
        // Vendedor, Asistente, Administrador
        payload['fecha_nacimiento'] = _fechaNacimiento!;
        payload['lugar_nacimiento'] = _lugarNacimientoCtrl.text.trim().isEmpty
            ? null
            : _lugarNacimientoCtrl.text.trim();
        payload['ubicacion_mapa'] = _ubicacionCtrl.text.trim().isEmpty
            ? null
            : _ubicacionCtrl.text.trim();
        payload['fecha_ingreso_empresa'] = _fechaIngreso!;
        payload['salario_mensual'] = num.tryParse(_salarioCtrl.text.trim());
        payload['beneficios'] = _beneficios.isEmpty ? null : _beneficios;
        payload['es_casado'] = _esCasado;
        payload['cantidad_hijos'] = _cantidadHijos;
        payload['tiene_casa'] = _tieneCasa;
        payload['tiene_vehiculo'] = _tieneVehiculo;
        payload['tipo_vehiculo'] =
            _tieneVehiculo && _tipoVehiculoCtrl.text.trim().isNotEmpty
            ? _tipoVehiculoCtrl.text.trim()
            : null;
        payload['placa'] = _tieneVehiculo && _placaCtrl.text.trim().isNotEmpty
            ? _placaCtrl.text.trim()
            : null;

        // Meta de ventas para vendedor y asistente
        if (_rol == 'vendedor' || _rol == 'asistente_administrativo') {
          final metaStr = _metaVentasCtrl.text.trim();
          if (metaStr.isNotEmpty) {
            payload['meta_ventas'] = num.tryParse(metaStr);
          }
        }
      }

      payload.removeWhere((_, v) => v == null);
      docs.removeWhere((_, v) => v == null);

      // En edición, conservar los otros documentos existentes.
      if (_editingUser != null && docs['otros_documentos'] is List) {
        final existing = _editingUser!.otrosDocumentos;
        final incoming = (docs['otros_documentos'] as List)
            .whereType<String>()
            .toList();
        final merged = <String>{...existing, ...incoming}.toList();
        docs['otros_documentos'] = merged;
      }

      payload.addAll(docs);

      if (widget.userId == null) {
        await ref.read(usersRepositoryProvider).createUser(payload);
      } else {
        await ref
            .read(usersRepositoryProvider)
            .updateUser(widget.userId!, payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String message = e.message ?? 'Error de red';
        if (status != null) {
          message = 'Error $status';
        }
        if (data is Map) {
          final err = data['error'];
          final details = data['details'];
          if (err is String && err.trim().isNotEmpty) {
            message = '$message: $err';
          } else if (details != null) {
            message = '$message: $details';
          }
        } else if (data is String && data.trim().isNotEmpty) {
          message = '$message: $data';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userId == null ? 'Nuevo Usuario' : 'Editar Usuario';

    return ModulePage(
      title: title,
      actions: [
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('1) Datos básicos'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              // Email y Password solo para usuarios que inician sesión (no contratista)
              if (_rol != 'contratista') ...[
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Requerido';
                    if (!t.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                if (widget.userId == null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                ],
              ],
              // Horario disponible solo para contratistas
              if (_rol == 'contratista') ...[
                TextFormField(
                  controller: _horarioDisponibleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario disponible',
                    prefixIcon: Icon(Icons.schedule_outlined),
                    hintText: 'ej: Lunes a Viernes 8:00am - 5:00pm',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 'vendedor',
                          child: Text('vendedor'),
                        ),
                        DropdownMenuItem(
                          value: 'tecnico_fijo',
                          child: Text('tecnico_fijo'),
                        ),
                        DropdownMenuItem(
                          value: 'contratista',
                          child: Text('contratista'),
                        ),
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text('administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'asistente_administrativo',
                          child: Text('asistente_administrativo'),
                        ),
                        DropdownMenuItem(
                          value: 'marketings',
                          child: Text('marketings'),
                        ),
                      ],
                      onChanged: (v) {
                        final next = v ?? 'vendedor';
                        setState(() => _rol = next);
                      },
                    ),
                  ),
                ],
              ),

              // === FORMULARIO DIFERENCIADO POR ROL ===
              if (_rol == 'contratista') ...[
                // Formulario simplificado para contratista SOLO
                const SizedBox(height: 20),
                const _SectionTitle('2) Datos de Contacto'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cedulaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ] else ...[
                // TODOS los demás roles (tecnico_fijo, vendedor, asistente, admin)
                const SizedBox(height: 20),
                const _SectionTitle('2) Datos Personales'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cedulaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Fecha de nacimiento',
                        value: _fechaNacimiento,
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                        onPick: (v) => setState(() => _fechaNacimiento = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lugarNacimientoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Lugar de nacimiento',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ubicacionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (mapa URL)',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _fillGpsLocation,
                  icon: const Icon(Icons.gps_fixed_outlined),
                  label: const Text('Capturar ubicación actual'),
                ),
                // Sección de familia y patrimonio
                const SizedBox(height: 20),
                const _SectionTitle('3) Información Personal'),
                const SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Es casado'),
                        value: _esCasado,
                        onChanged: (v) =>
                            setState(() => _esCasado = v ?? false),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: _cantidadHijos.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad de hijos',
                        ),
                        onChanged: (v) => setState(
                          () => _cantidadHijos = int.tryParse(v) ?? 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Tiene casa propia'),
                  value: _tieneCasa,
                  onChanged: (v) => setState(() => _tieneCasa = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Tiene vehículo'),
                  value: _tieneVehiculo,
                  onChanged: (v) => setState(() => _tieneVehiculo = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_tieneVehiculo) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tipoVehiculoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de vehículo',
                      hintText: 'ej: Auto, Moto, Camión',
                    ),
                    validator: (v) =>
                        _tieneVehiculo && (v == null || v.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'ej: ABC-1234',
                    ),
                  ),
                ],
                // Sección laboral
                const SizedBox(height: 20),
                const _SectionTitle('4) Información Laboral'),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Fecha de ingreso',
                  value: _fechaIngreso,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  onPick: (v) => setState(() => _fechaIngreso = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salarioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Salario mensual',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (num.tryParse(v.trim()) == null) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ultimoTrabajoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Último trabajo',
                    hintText: 'ej: Empresa anterior',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivoSalidaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de salida',
                  ),
                ),
                // Meta de ventas para vendedor y asistente
                if (_rol == 'vendedor' ||
                    _rol == 'asistente_administrativo') ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('5) Meta de Ventas'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _metaVentasCtrl,
                    decoration: InputDecoration(
                      labelText: 'Meta de ventas (quincenal)',
                      prefixIcon: const Icon(Icons.trending_up_outlined),
                      hintText: _rol == 'vendedor' ? '50000' : '35000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (num.tryParse(v.trim()) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ],
                // Especialidades para técnico fijo
                if (_rol == 'tecnico_fijo') ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('5) Especialidades'),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agregar Especialidades',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _especialidadCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Especialidad',
                                    hintText: 'ej: Reparación de tuberías',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _addEspecialidad,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_especialidades.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Especialidades agregadas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._especialidades.asMap().entries.map((entry) {
                              final index = entry.key;
                              final esp = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 20,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            esp,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      onPressed: () =>
                                          _removeEspecialidad(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                // Licencia de conducir para técnico fijo
                if (_rol == 'tecnico_fijo') ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('6) Licencia de Conducir'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _licenciaConducirNumeroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número de licencia',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: (_readingLicencia || _saving)
                              ? null
                              : _autoFillFromLicencia,
                          icon: _readingLicencia
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Leer datos de licencia'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: 'Fecha de vencimiento',
                    value: _licenciaVencimiento,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    onPick: (v) => setState(() => _licenciaVencimiento = v),
                  ),
                ],
              ],
              // Sección de cédula frontal con lectura AI para contratista
              if (_rol == 'contratista') ...[
                const SizedBox(height: 20),
                const _SectionTitle('3) Cédula'),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DocumentPreview(
                        label: 'Cédula frontal',
                        imageBytes: _cedulaFrontal?.bytes,
                        imageUrl: _resolvePublicUrl(
                          _editingUser?.cedulaFrontalUrl,
                        ),
                        onPick: () =>
                            _pickAndSetSingle((d) => _cedulaFrontal = d),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed:
                            (_readingCedula || _readingLicencia || _saving)
                            ? null
                            : _autoFillFromCedula,
                        icon: _readingCedula
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Leer datos de cédula'),
                      ),
                    ],
                  ),
                ),
              ],
              // Áreas de trabajo dinámicas para contratista
              if (_rol == 'contratista') ...[
                const SizedBox(height: 20),
                const _SectionTitle('4) Áreas de Trabajo'),
                const SizedBox(height: 12),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agregar Áreas de Trabajo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _areaTrabajoCrtlr,
                                decoration: const InputDecoration(
                                  labelText: 'Área',
                                  hintText:
                                      'ej: Puertas, Cerco eléctrico, Cámaras',
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _addAreaTrabajo,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_areasTrabajo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Áreas de trabajo agregadas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._areasTrabajo.asMap().entries.map((entry) {
                            final index = entry.key;
                            final area = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            area,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _removeAreaTrabajo(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              // Beneficios para contratista
              if (_rol == 'contratista') ...[
                const SizedBox(height: 20),
                const _SectionTitle('5) Beneficios'),
                const SizedBox(height: 12),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agregar Beneficios',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _beneficioNombreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipoBeneficio,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'monto',
                                    child: Text('Monto'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'porcentaje',
                                    child: Text('Porciento'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _tipoBeneficio = v);
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _beneficioMontoCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _tipoBeneficio == 'porcentaje'
                                      ? '%'
                                      : 'Valor',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                  suffixText: _tipoBeneficio == 'porcentaje'
                                      ? '%'
                                      : '\$',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _addBeneficio,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'Agregar',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_beneficios.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Beneficios agregados',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._beneficios.asMap().entries.map((entry) {
                            final index = entry.key;
                            final b = entry.value;
                            final tipo = b['tipo'] ?? 'monto';
                            final valor = b['monto'];
                            final display = tipo == 'porcentaje'
                                ? '$valor%'
                                : '\$$valor';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${b['nombre']} - $display',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _removeBeneficio(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              const _SectionTitle('7) Documentos (subida y vista previa)'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    child: DocumentPreview(
                      label: 'Foto perfil',
                      imageBytes: _fotoPerfil?.bytes,
                      imageUrl: _resolvePublicUrl(_editingUser?.fotoPerfilUrl),
                      onPick: () => _pickAndSetSingle((d) => _fotoPerfil = d),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DocumentPreview(
                          label: 'Cédula frontal',
                          imageBytes: _cedulaFrontal?.bytes,
                          imageUrl: _resolvePublicUrl(
                            _editingUser?.cedulaFrontalUrl,
                          ),
                          onPick: () =>
                              _pickAndSetSingle((d) => _cedulaFrontal = d),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed:
                              (_readingCedula || _readingLicencia || _saving)
                              ? null
                              : _autoFillFromCedula,
                          icon: _readingCedula
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Leer datos de cédula'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DocumentPreview(
                      label: 'Cédula posterior',
                      imageBytes: _cedulaPosterior?.bytes,
                      imageUrl: _resolvePublicUrl(
                        _editingUser?.cedulaPosteriorUrl,
                      ),
                      onPick: () =>
                          _pickAndSetSingle((d) => _cedulaPosterior = d),
                    ),
                  ),
                  if (_rol == 'tecnico_fijo')
                    SizedBox(
                      width: 280,
                      child: DocumentPreview(
                        label: 'Licencia conducir',
                        imageBytes: _licenciaConducir?.bytes,
                        imageUrl: _resolvePublicUrl(
                          _editingUser?.licenciaConducirUrl,
                        ),
                        onPick: () =>
                            _pickAndSetSingle((d) => _licenciaConducir = d),
                      ),
                    ),
                  SizedBox(
                    width: 280,
                    child: DocumentPreview(
                      label: 'Carta trabajo',
                      imageBytes: _cartaTrabajo?.bytes,
                      imageUrl: _resolvePublicUrl(
                        _editingUser?.cartaTrabajoUrl,
                      ),
                      onPick: () => _pickAndSetSingle((d) => _cartaTrabajo = d),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DocumentPreview(
                      label: 'Curriculum Vitae',
                      imageBytes: _curriculumVitae?.bytes,
                      imageUrl: _resolvePublicUrl(
                        _editingUser?.curriculumVitaeUrl,
                      ),
                      onPick: () =>
                          _pickAndSetSingle((d) => _curriculumVitae = d),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Otros documentos',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () async {
                                  final res = await FilePicker.platform
                                      .pickFiles(
                                        allowMultiple: true,
                                        type: FileType.image,
                                        withData: true,
                                      );
                                  final files = res?.files ?? const [];
                                  if (!mounted) return;
                                  if (files.isEmpty) return;
                                  setState(() {
                                    for (final f in files) {
                                      if (f.bytes == null &&
                                          (f.path == null ||
                                              f.path!.trim().isEmpty)) {
                                        continue;
                                      }
                                      _otrosDocumentos.add(
                                        _PickedDoc(
                                          path: f.path,
                                          bytes: f.bytes,
                                        ),
                                      );
                                    }
                                  });
                                },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text('Agregar (${_otrosDocumentos.length})'),
                        ),
                        if (_otrosDocumentos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(
                              _otrosDocumentos.length,
                              (i) => InputChip(
                                label: Text('Nuevo ${i + 1}'),
                                onDeleted: _saving
                                    ? null
                                    : () => setState(
                                        () => _otrosDocumentos.removeAt(i),
                                      ),
                              ),
                            ),
                          ),
                        ],
                        if ((_editingUser?.otrosDocumentos ?? const [])
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Existentes: ${_editingUser!.otrosDocumentos.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onPick,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(_fmt(value)),
      ),
    );
  }
}

class _PickedDoc {
  final String? path;
  final Uint8List? bytes;

  const _PickedDoc({required this.path, required this.bytes});
}
