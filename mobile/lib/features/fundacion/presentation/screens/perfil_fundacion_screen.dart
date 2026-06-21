import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/auth_alert_banner.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/loading_button.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/fundacion_perfil.dart';
import 'package:voluntapp_mobile/features/fundacion/data/repositories/fundacion_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/tag_multi_select.dart';

/// Screen 12 — Perfil Fundación
class PerfilFundacionScreen extends ConsumerStatefulWidget {
  const PerfilFundacionScreen({super.key});

  @override
  ConsumerState<PerfilFundacionScreen> createState() =>
      _PerfilFundacionScreenState();
}

class _PerfilFundacionScreenState extends ConsumerState<PerfilFundacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nitController = TextEditingController();
  final _representanteController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _webController = TextEditingController();
  final _direccionController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _documentoController = TextEditingController();

  FundacionPerfil? _perfil;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;
  String _error = '';
  String _success = '';
  final Map<String, String> _fieldErrors = {};
  int? _departamentoId;
  int? _municipioId;
  List<int> _areas = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _nitController.dispose();
    _representanteController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _webController.dispose();
    _direccionController.dispose();
    _descripcionController.dispose();
    _documentoController.dispose();
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
        ref.read(catalogRepositoryProvider).getAreasImpacto(),
      ]);
      final perfil = await ref.read(fundacionRepositoryProvider).fetchPerfil();
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

  void _populateForm(FundacionPerfil perfil) {
    _nombreController.text = perfil.nombre;
    _nitController.text = perfil.nit;
    _representanteController.text = perfil.representanteLegal;
    _correoController.text = perfil.correoInstitucional ?? '';
    _telefonoController.text = perfil.telefono;
    _webController.text = perfil.paginaWeb ?? '';
    _direccionController.text = perfil.direccion;
    _descripcionController.text = perfil.descripcion;
    _documentoController.text = '';
    _municipioId = perfil.municipio?.id;
    _departamentoId = perfil.municipio?.departamento?.id;
    _areas = perfil.areas.map((a) => a.id).toList();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(fundacionRepositoryProvider);
      final updated = await repo.actualizarLogo(picked.path);
      ref.invalidate(fundacionPerfilProvider);
      if (!mounted) return;
      setState(() {
        _perfil = updated;
        _success = 'Logo actualizado.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  FundacionPerfilInput _buildInput() {
    return FundacionPerfilInput(
      nombre: _nombreController.text.trim(),
      nit: _nitController.text.trim(),
      representanteLegal: _representanteController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      municipioId: _municipioId!,
      descripcion: _descripcionController.text.trim(),
      documentoLegal: _documentoController.text.trim().isNotEmpty
          ? _documentoController.text.trim()
          : 'registrado',
      correoInstitucional: _correoController.text.trim(),
      paginaWeb: _webController.text.trim(),
      areas: _areas,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_municipioId == null) {
      setState(() => _fieldErrors['municipio_id'] = 'Selecciona un municipio.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
      _success = '';
      _fieldErrors.clear();
    });

    try {
      final repo = ref.read(fundacionRepositoryProvider);
      final input = _buildInput();
      final saved = _perfil == null
          ? await repo.createPerfil(input)
          : await repo.updatePerfil(_perfil!.id, input);

      ref.invalidate(fundacionPerfilProvider);
      if (!mounted) return;
      setState(() {
        _perfil = saved;
        _editMode = false;
        _success = 'Perfil guardado correctamente.';
      });
    } on ValidationException catch (e) {
      setState(() => _fieldErrors.addAll(e.errors));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al guardar el perfil.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departamentos = ref.watch(departamentosProvider).valueOrNull ?? [];
    final municipiosAsync = _departamentoId == null
        ? const AsyncValue<List<Municipio>>.data([])
        : ref.watch(municipiosProvider(_departamentoId!));
    final areas = ref.watch(areasImpactoProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Fundación'),
        actions: [
          if (_perfil != null && !_editMode)
            IconButton(
              onPressed: () => setState(() => _editMode = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
            ),
          const NotificacionAppBarAction(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error.isNotEmpty) AuthErrorBanner(message: _error),
                if (_success.isNotEmpty) AuthSuccessBanner(message: _success),
                if (_perfil == null && !_editMode) ...[
                  const Text(
                    'Aún no has registrado tu fundación. Completa el formulario para iniciar el proceso de aprobación.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _editMode = true),
                    child: const Text('Registrar fundación'),
                  ),
                ] else if (_editMode)
                  _buildForm(departamentos, municipiosAsync, areas)
                else if (_perfil != null)
                  _buildView(_perfil!),
              ],
            ),
    );
  }

  Widget _buildView(FundacionPerfil perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            leading: GestureDetector(
              onTap: _pickAndUploadLogo,
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: perfil.logo != null
                        ? NetworkImage(perfil.logo!)
                        : null,
                    child: perfil.logo == null
                        ? Text(perfil.nombre.isNotEmpty
                            ? perfil.nombre[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(perfil.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('NIT: ${perfil.nit}'),
            trailing: EstadoBadge(
                estado: perfil.estadoVerificacion, tipo: 'fundacion'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Representante', perfil.representanteLegal),
                _detail('Teléfono', perfil.telefono),
                if (perfil.correoInstitucional != null)
                  _detail('Correo', perfil.correoInstitucional!),
                if (perfil.paginaWeb != null) _detail('Web', perfil.paginaWeb!),
                _detail('Dirección', perfil.direccion),
                if (perfil.municipio != null)
                  _detail(
                    'Ubicación',
                    '${perfil.municipio!.nombre}, ${perfil.municipio!.departamento?.nombre ?? ''}',
                  ),
                const SizedBox(height: 12),
                const Text('Descripción',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(perfil.descripcion),
                if (perfil.areas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: perfil.areas
                        .map((a) => Chip(label: Text(a.nombre)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (perfil.isRechazada && perfil.motivoRechazo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                AuthErrorBanner(message: 'Rechazada: ${perfil.motivoRechazo}'),
          ),
      ],
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildForm(
    List<Departamento> departamentos,
    AsyncValue<List<Municipio>> municipiosAsync,
    List<CatalogItem> areas,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nombreController,
            decoration:
                const InputDecoration(labelText: 'Nombre de la fundación *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nitController,
            enabled: _perfil == null,
            decoration: const InputDecoration(
                labelText: 'NIT *', hintText: '0000000-0'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _representanteController,
            decoration:
                const InputDecoration(labelText: 'Representante legal *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _correoController,
            decoration:
                const InputDecoration(labelText: 'Correo institucional'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(labelText: 'Teléfono *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _webController,
            decoration: const InputDecoration(labelText: 'Página web'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccionController,
            decoration: const InputDecoration(labelText: 'Dirección *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _departamentoId,
            decoration: const InputDecoration(labelText: 'Departamento *'),
            items: departamentos
                .map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
                .toList(),
            onChanged: (v) => setState(() {
              _departamentoId = v;
              _municipioId = null;
            }),
          ),
          const SizedBox(height: 12),
          municipiosAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error al cargar municipios'),
            data: (municipios) => DropdownButtonFormField<int>(
              initialValue: _municipioId,
              decoration: InputDecoration(
                labelText: 'Municipio *',
                errorText: _fieldErrors['municipio_id'],
              ),
              items: municipios
                  .map((m) =>
                      DropdownMenuItem(value: m.id, child: Text(m.nombre)))
                  .toList(),
              onChanged: _departamentoId == null
                  ? null
                  : (v) => setState(() => _municipioId = v),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          if (_perfil == null) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentoController,
              decoration: const InputDecoration(
                labelText: 'URL enlace documentos *',
                hintText: 'Drive, Dropbox, etc.',
                helperText: 'Ingresa un enlace de una carpeta o archivo compartido en la nube donde adjuntes la cédula del representante legal, el certificado de Cámara de Comercio y/o el RUT.',
                helperMaxLines: 3,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
          ],
          const SizedBox(height: 16),
          const Text('Áreas de impacto',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TagMultiSelect(
            options: areas.map((a) => (id: a.id, nombre: a.nombre)).toList(),
            selectedIds: _areas,
            onChanged: (ids) => setState(() => _areas = ids),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_perfil != null)
                OutlinedButton(
                  onPressed:
                      _saving ? null : () => setState(() => _editMode = false),
                  child: const Text('Cancelar'),
                ),
              const Spacer(),
              LoadingButton(
                onPressed: _save,
                loading: _saving,
                label: 'Guardar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
