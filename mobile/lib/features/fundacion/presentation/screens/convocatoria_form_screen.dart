import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/utils/media_url.dart';
import 'package:voluntapp_mobile/features/auth/presentation/widgets/loading_button.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/publicacion_input.dart';
import 'package:voluntapp_mobile/features/fundacion/data/repositories/fundacion_publicacion_repository.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/tag_multi_select.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';

/// Screen 13.1 — Formulario convocatoria
class ConvocatoriaFormScreen extends ConsumerStatefulWidget {
  const ConvocatoriaFormScreen({super.key, this.publicacion});

  final Publicacion? publicacion;

  @override
  ConsumerState<ConvocatoriaFormScreen> createState() => _ConvocatoriaFormScreenState();
}

class _ConvocatoriaFormScreenState extends ConsumerState<ConvocatoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _enlaceController = TextEditingController();
  final _requisitosController = TextEditingController();
  final _cupoController = TextEditingController(text: '1');

  bool _saving = false;
  String _error = '';
  String? _modalidad;
  int? _categoriaId;
  int? _departamentoId;
  int? _municipioId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  List<int> _habilidades = [];
  List<PublicacionImagen> _imagenesActuales = [];
  final List<String> _imagenesNuevas = [];

  bool get _editando => widget.publicacion != null;

  @override
  void initState() {
    super.initState();
    _initCatalogos();
    if (widget.publicacion != null) _populate(widget.publicacion!);
  }

  Future<void> _initCatalogos() async {
    await Future.wait([
      ref.read(catalogRepositoryProvider).getDepartamentos(),
      ref.read(catalogRepositoryProvider).getAreasImpacto(),
      ref.read(catalogRepositoryProvider).getHabilidades(),
    ]);
  }

  void _populate(Publicacion pub) {
    _tituloController.text = pub.titulo;
    _descripcionController.text = pub.descripcion;
    _direccionController.text = pub.direccionExacta ?? '';
    _enlaceController.text = pub.enlaceVirtual ?? '';
    _requisitosController.text = pub.requisitosAdicionales ?? '';
    _cupoController.text = '${pub.cupoMaximo ?? 1}';
    _modalidad = pub.modalidad;
    _categoriaId = pub.categoriaId;
    _municipioId = pub.municipio?.id;
    _departamentoId = pub.municipio?.departamento?.id;
    _imagenesActuales = List.from(pub.imagenes);
    _habilidades = pub.habilidades.map((h) => h.id).toList();
    _fechaInicio = DateTime.tryParse(pub.fechaInicio ?? '');
    _fechaFin = DateTime.tryParse(pub.fechaFin ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _enlaceController.dispose();
    _requisitosController.dispose();
    _cupoController.dispose();
    super.dispose();
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  PublicacionInput _buildInput() {
    final needsMunicipio = _modalidad == 'PRESENCIAL' || _modalidad == 'HIBRIDA';
    return PublicacionInput(
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      categoriaId: _categoriaId!,
      modalidad: _modalidad!,
      fechaInicio: _formatDate(_fechaInicio),
      fechaFin: _formatDate(_fechaFin),
      cupoMaximo: int.tryParse(_cupoController.text.trim()) ?? 1,
      municipioId: needsMunicipio ? _municipioId : null,
      direccionExacta: _direccionController.text.trim(),
      enlaceVirtual: _enlaceController.text.trim(),
      horaInicio: _formatTime(_horaInicio),
      horaFin: _formatTime(_horaFin),
      requisitosAdicionales: _requisitosController.text.trim(),
      habilidades: _habilidades,
    );
  }

  Future<void> _pickImages() async {
    final max = 5 - _imagenesActuales.length - _imagenesNuevas.length;
    if (max <= 0) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _imagenesNuevas.addAll(files.take(max).map((f) => f.path)));
  }

  Future<void> _eliminarImagenActual(PublicacionImagen img) async {
    if (!_editando || img.id == null) return;
    try {
      final updated = await ref
          .read(fundacionPublicacionRepositoryProvider)
          .eliminarImagen(widget.publicacion!.id, img.id!);
      setState(() => _imagenesActuales = List.from(updated.imagenes));
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Error al eliminar imagen.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null || _modalidad == null || _fechaInicio == null || _fechaFin == null) {
      setState(() => _error = 'Completa categoría, modalidad y fechas.');
      return;
    }
    if ((_modalidad == 'PRESENCIAL' || _modalidad == 'HIBRIDA') && _municipioId == null) {
      setState(() => _error = 'Selecciona municipio para modalidad presencial/híbrida.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final repo = ref.read(fundacionPublicacionRepositoryProvider);
      final input = _buildInput();
      Publicacion saved;
      if (_editando) {
        saved = await repo.update(widget.publicacion!.id, input);
      } else {
        saved = await repo.create(input);
      }

      if (_imagenesNuevas.isNotEmpty) {
        saved = await repo.subirImagenes(saved.id, _imagenesNuevas);
      }

      if (!mounted) return;
      context.pop(true);
    } on ValidationException catch (e) {
      setState(() => _error = e.errors.values.firstOrNull ?? e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al guardar la convocatoria.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool inicio}) async {
    final initial = inicio ? _fechaInicio : _fechaFin;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (inicio) {
        _fechaInicio = picked;
      } else {
        _fechaFin = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(areasImpactoProvider).valueOrNull ?? [];
    final habilidades = ref.watch(habilidadesProvider).valueOrNull ?? [];
    final departamentos = ref.watch(departamentosProvider).valueOrNull ?? [];
    final municipiosAsync = _departamentoId == null
        ? const AsyncValue<List<Municipio>>.data([])
        : ref.watch(municipiosProvider(_departamentoId!));
    final apiBase = ref.watch(appConfigProvider).apiBaseUrl;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar convocatoria' : 'Nueva convocatoria')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error, style: const TextStyle(color: AppColors.danger)),
              ),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(labelText: 'Área de impacto *'),
              items: areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modalidad,
              decoration: const InputDecoration(labelText: 'Modalidad *'),
              items: const [
                DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                DropdownMenuItem(value: 'VIRTUAL', child: Text('Virtual')),
                DropdownMenuItem(value: 'HIBRIDA', child: Text('Híbrida')),
              ],
              onChanged: (v) => setState(() => _modalidad = v),
            ),
            if (_modalidad != 'VIRTUAL') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _departamentoId,
                decoration: const InputDecoration(labelText: 'Departamento *'),
                items: departamentos
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _departamentoId = v;
                  _municipioId = null;
                }),
              ),
              const SizedBox(height: 12),
              municipiosAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (municipios) => DropdownButtonFormField<int>(
                  initialValue: _municipioId,
                  decoration: const InputDecoration(labelText: 'Municipio *'),
                  items: municipios
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre)))
                      .toList(),
                  onChanged: _departamentoId == null ? null : (v) => setState(() => _municipioId = v),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha inicio *'),
              subtitle: Text(_formatDate(_fechaInicio).isEmpty ? 'Seleccionar' : _formatDate(_fechaInicio)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(inicio: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha fin *'),
              subtitle: Text(_formatDate(_fechaFin).isEmpty ? 'Seleccionar' : _formatDate(_fechaFin)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(inicio: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cupoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cupo máximo *'),
              validator: (v) => int.tryParse(v ?? '') == null ? 'Número inválido' : null,
            ),
            if (_modalidad != 'PRESENCIAL') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _enlaceController,
                decoration: const InputDecoration(labelText: 'Enlace virtual'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección exacta'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _requisitosController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Requisitos adicionales'),
            ),
            const SizedBox(height: 16),
            const Text('Habilidades requeridas', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TagMultiSelect(
              options: habilidades.map((h) => (id: h.id, nombre: h.nombre)).toList(),
              selectedIds: _habilidades,
              onChanged: (ids) => setState(() => _habilidades = ids),
            ),
            const SizedBox(height: 16),
            const Text('Imágenes (máx. 5)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final img in _imagenesActuales)
                  _ImageThumb(
                    url: resolveMediaUrl(img.url, apiBase),
                    onRemove: img.id != null ? () => _eliminarImagenActual(img) : null,
                  ),
                for (final path in _imagenesNuevas)
                  _ImageThumb(
                    url: path,
                    isLocal: true,
                    onRemove: () => setState(() => _imagenesNuevas.remove(path)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _imagenesActuales.length + _imagenesNuevas.length >= 5 ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Agregar imágenes'),
            ),
            const SizedBox(height: 24),
            LoadingButton(label: 'Guardar', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.url, this.onRemove, this.isLocal = false});

  final String url;
  final VoidCallback? onRemove;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLocal
              ? Image.file(File(url), width: 72, height: 72, fit: BoxFit.cover)
              : Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 14),
            ),
          ),
      ],
    );
  }
}
