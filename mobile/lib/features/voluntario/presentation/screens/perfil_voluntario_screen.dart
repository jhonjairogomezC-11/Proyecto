import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_alert_banner.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/loading_button.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/voluntario_perfil.dart';
import 'package:voluntapp_mobile/features/voluntario/data/repositories/voluntario_repository.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/tag_multi_select.dart';

/// Screen 06 — Perfil Voluntario (crear / editar / ver).
class PerfilVoluntarioScreen extends ConsumerStatefulWidget {
  const PerfilVoluntarioScreen({super.key});

  @override
  ConsumerState<PerfilVoluntarioScreen> createState() => _PerfilVoluntarioScreenState();
}

class _PerfilVoluntarioScreenState extends ConsumerState<PerfilVoluntarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroDocController = TextEditingController();
  final _experienciaController = TextEditingController();

  VoluntarioPerfil? _perfil;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;
  String _error = '';
  String _success = '';
  final Map<String, String> _fieldErrors = {};

  String _tipoDocumento = '';
  String _genero = '';
  String _disponibilidad = '';
  int? _departamentoId;
  int? _municipioId;
  DateTime? _fechaNacimiento;
  List<int> _habilidades = [];
  List<int> _intereses = [];

  @override
  void dispose() {
    _numeroDocController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        ref.read(catalogRepositoryProvider).getDepartamentos(),
        ref.read(catalogRepositoryProvider).getHabilidades(),
        ref.read(catalogRepositoryProvider).getIntereses(),
      ]);

      final perfil = await ref.read(voluntarioRepositoryProvider).fetchPerfil();
      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        if (perfil != null) _populateForm(perfil);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Error al cargar el perfil.';
        _loading = false;
      });
    }
  }

  void _populateForm(VoluntarioPerfil perfil) {
    _tipoDocumento = perfil.tipoDocumento;
    _numeroDocController.text = perfil.numeroDocumento;
    _genero = perfil.genero;
    _disponibilidad = perfil.disponibilidad;
    _experienciaController.text = perfil.experiencia ?? '';
    _habilidades = perfil.habilidades.map((h) => h.id).toList();
    _intereses = perfil.intereses.map((i) => i.id).toList();
    _municipioId = perfil.municipio?.id;
    _departamentoId = perfil.municipio?.departamento?.id;
    _fechaNacimiento = DateTime.tryParse(perfil.fechaNacimiento);
  }

  DateTime get _maxFechaNac {
    final now = DateTime.now();
    return DateTime(now.year - 14, now.month, now.day);
  }

  Future<void> _pickFechaNacimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? _maxFechaNac,
      firstDate: DateTime(1940),
      lastDate: _maxFechaNac,
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  VoluntarioPerfilInput _buildInput() {
    return VoluntarioPerfilInput(
      tipoDocumento: _tipoDocumento,
      numeroDocumento: _numeroDocController.text.trim(),
      fechaNacimiento: DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
      genero: _genero,
      municipioId: _municipioId!,
      disponibilidad: _disponibilidad,
      experiencia: _experienciaController.text.trim().isEmpty
          ? null
          : _experienciaController.text.trim(),
      habilidades: _habilidades,
      intereses: _intereses,
    );
  }

  bool _validateForm() {
    _fieldErrors.clear();
    var ok = _formKey.currentState?.validate() ?? false;

    if (_tipoDocumento.isEmpty) {
      _fieldErrors['tipo_documento'] = 'Requerido.';
      ok = false;
    }
    if (_genero.isEmpty) {
      _fieldErrors['genero'] = 'Requerido.';
      ok = false;
    }
    if (_departamentoId == null) {
      _fieldErrors['departamento_id'] = 'Requerido.';
      ok = false;
    }
    if (_municipioId == null) {
      _fieldErrors['municipio_id'] = 'Requerido.';
      ok = false;
    }
    if (_disponibilidad.isEmpty) {
      _fieldErrors['disponibilidad'] = 'Requerido.';
      ok = false;
    }
    if (_fechaNacimiento == null) {
      _fieldErrors['fecha_nacimiento'] = 'Requerido.';
      ok = false;
    }

    setState(() {});
    return ok;
  }

  Future<void> _save() async {
    if (!_validateForm()) return;

    setState(() {
      _saving = true;
      _error = '';
      _success = '';
    });

    try {
      final repo = ref.read(voluntarioRepositoryProvider);
      final input = _buildInput();
      final saved = _perfil == null
          ? await repo.createPerfil(input)
          : await repo.updatePerfil(input);

      ref.invalidate(voluntarioPerfilProvider);

      if (!mounted) return;
      setState(() {
        _perfil = saved;
        _editMode = false;
        _success = 'Perfil guardado correctamente.';
        _populateForm(saved);
      });
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors.addAll(e.errors);
        _error = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error al guardar el perfil.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).usuario;
    final departamentosAsync = ref.watch(departamentosProvider);
    final habilidadesAsync = ref.watch(habilidadesProvider);
    final interesesAsync = ref.watch(interesesProvider);
    final municipiosAsync = ref.watch(municipiosProvider(_departamentoId ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (!_loading && _perfil != null && !_editMode)
            IconButton(
              tooltip: 'Editar',
              onPressed: () => setState(() {
                _editMode = true;
                _success = '';
              }),
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthErrorBanner(message: _error),
                  AuthSuccessBanner(message: _success),
                  if (_perfil == null && !_editMode) _buildEmptyState(),
                  if (_editMode) _buildForm(
                    departamentosAsync,
                    municipiosAsync,
                    habilidadesAsync,
                    interesesAsync,
                  ),
                  if (_perfil != null && !_editMode) _buildView(user?.nombre, user?.email),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Aún no tienes un perfil de voluntario. Complétalo para postularte a convocatorias.',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() => _editMode = true),
          child: const Text('Crear mi perfil'),
        ),
      ],
    );
  }

  Widget _buildView(String? nombre, String? email) {
    final perfil = _perfil!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (nombre ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (email != null)
                        Text(email, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detail('Documento', '${perfil.tipoDocumento} ${perfil.numeroDocumento}'),
            _detail('Nacimiento', perfil.fechaNacimiento),
            _detail('Género', VoluntarioOptions.labelGenero(perfil.genero)),
            _detail(
              'Disponibilidad',
              VoluntarioOptions.labelDisponibilidad(perfil.disponibilidad),
            ),
            if (perfil.municipio != null)
              _detail(
                'Municipio',
                '${perfil.municipio!.nombre}, ${perfil.municipio!.departamento?.nombre ?? ''}',
              ),
            if (perfil.experiencia != null && perfil.experiencia!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Experiencia', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(perfil.experiencia!),
            ],
            if (perfil.habilidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final h in perfil.habilidades)
                    Chip(label: Text(h.nombre), backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
                ],
              ),
            ],
            if (perfil.intereses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Intereses', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final i in perfil.intereses)
                    Chip(label: Text(i.nombre), backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildForm(
    AsyncValue<List<Departamento>> departamentosAsync,
    AsyncValue<List<Municipio>> municipiosAsync,
    AsyncValue<List<CatalogItem>> habilidadesAsync,
    AsyncValue<List<CatalogItem>> interesesAsync,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _perfil == null ? 'Crear perfil de voluntario' : 'Editar perfil',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tipoDocumento.isEmpty ? null : _tipoDocumento,
            decoration: InputDecoration(
              labelText: 'Tipo de documento',
              errorText: _fieldErrors['tipo_documento'],
            ),
            items: [
              for (final t in VoluntarioOptions.tiposDocumento)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _tipoDocumento = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _numeroDocController,
            decoration: InputDecoration(
              labelText: 'Número de documento',
              errorText: _fieldErrors['numero_documento'],
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido.' : null,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickFechaNacimiento,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                errorText: _fieldErrors['fecha_nacimiento'],
              ),
              child: Text(
                _fechaNacimiento == null
                    ? 'Seleccionar…'
                    : DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _genero.isEmpty ? null : _genero,
            decoration: InputDecoration(
              labelText: 'Género',
              errorText: _fieldErrors['genero'],
            ),
            items: [
              for (final g in VoluntarioOptions.generos)
                DropdownMenuItem(value: g.$1, child: Text(g.$2)),
            ],
            onChanged: (v) => setState(() => _genero = v ?? ''),
          ),
          const SizedBox(height: 12),
          departamentosAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error cargando departamentos'),
            data: (departamentos) => DropdownButtonFormField<int>(
              value: _departamentoId,
              decoration: InputDecoration(
                labelText: 'Departamento',
                errorText: _fieldErrors['departamento_id'],
              ),
              items: [
                for (final d in departamentos)
                  DropdownMenuItem(value: d.id, child: Text(d.nombre)),
              ],
              onChanged: (v) => setState(() {
                _departamentoId = v;
                _municipioId = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          municipiosAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error cargando municipios'),
            data: (municipios) => DropdownButtonFormField<int>(
              value: _municipioId,
              decoration: InputDecoration(
                labelText: 'Municipio',
                errorText: _fieldErrors['municipio_id'],
              ),
              items: [
                for (final m in municipios)
                  DropdownMenuItem(value: m.id, child: Text(m.nombre)),
              ],
              onChanged: _departamentoId == null
                  ? null
                  : (v) => setState(() => _municipioId = v),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _disponibilidad.isEmpty ? null : _disponibilidad,
            decoration: InputDecoration(
              labelText: 'Disponibilidad',
              errorText: _fieldErrors['disponibilidad'],
            ),
            items: [
              for (final d in VoluntarioOptions.disponibilidades)
                DropdownMenuItem(value: d.$1, child: Text(d.$2)),
            ],
            onChanged: (v) => setState(() => _disponibilidad = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _experienciaController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Experiencia previa (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          habilidadesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => TagMultiSelect(
              options: items.map((i) => (id: i.id, nombre: i.nombre)).toList(),
              selectedIds: _habilidades,
              onChanged: (ids) => setState(() => _habilidades = ids),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Intereses', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          interesesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => TagMultiSelect(
              options: items.map((i) => (id: i.id, nombre: i.nombre)).toList(),
              selectedIds: _intereses,
              onChanged: (ids) => setState(() => _intereses = ids),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_perfil != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _editMode = false;
                              if (_perfil != null) _populateForm(_perfil!);
                            }),
                    child: const Text('Cancelar'),
                  ),
                ),
              if (_perfil != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LoadingButton(
                  label: 'Guardar perfil',
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
