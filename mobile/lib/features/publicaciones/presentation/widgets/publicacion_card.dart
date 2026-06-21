import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/publicaciones/presentation/widgets/image_carousel.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

class PublicacionCard extends StatelessWidget {
  const PublicacionCard({
    super.key,
    required this.publicacion,
    required this.esFavorito,
    required this.yaPostulado,
    required this.onTap,
    required this.onToggleFavorito,
    required this.onPostular,
  });

  final Publicacion publicacion;
  final bool esFavorito;
  final bool yaPostulado;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorito;
  final VoidCallback onPostular;

  @override
  Widget build(BuildContext context) {
    final desc = publicacion.descripcion;
    final preview = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child:
                      ImageCarousel(urls: publicacion.imageUrls, height: 160),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton.filledTonal(
                    onPressed: onToggleFavorito,
                    icon: Icon(
                      esFavorito ? Icons.favorite : Icons.favorite_border,
                      color: esFavorito ? AppColors.danger : null,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: _modalidadLabel(publicacion.modalidad)),
                      if (publicacion.categoriaNombre != null)
                        _Chip(label: publicacion.categoriaNombre!, muted: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    publicacion.titulo,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (publicacion.fundacionNombre != null)
                    _InfoRow(
                        Icons.business_outlined, publicacion.fundacionNombre!),
                  if (publicacion.municipio != null)
                    _InfoRow(
                      Icons.location_on_outlined,
                      '${publicacion.municipio!.nombre}, ${publicacion.municipio!.departamento?.nombre ?? ''}',
                    ),
                  _InfoRow(
                    Icons.calendar_month_outlined,
                    '${formatShortDate(publicacion.fechaInicio)} – ${formatShortDate(publicacion.fechaFin)}',
                  ),
                  if (publicacion.cupoMaximo != null)
                    _InfoRow(Icons.people_outline,
                        '${publicacion.cupoMaximo} cupos'),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(preview,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                            onPressed: onTap,
                            child: const Text('Ver detalles')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: yaPostulado ? null : onPostular,
                          child: Text(yaPostulado ? 'Postulado' : 'Postularme'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _modalidadLabel(String value) {
    return switch (value) {
      'PRESENCIAL' => 'Presencial',
      'VIRTUAL' => 'Virtual',
      'HIBRIDA' => 'Híbrida',
      _ => value,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.background
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
