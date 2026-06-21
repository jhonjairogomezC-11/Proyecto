import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Versión compacta del PublicacionCard para mostrar más publicaciones en pantalla
class PublicacionCardCompact extends StatelessWidget {
  const PublicacionCardCompact({
    super.key,
    required this.publicacion,
    required this.esFavorito,
    required this.yaPostulado,
    required this.onTap,
    required this.onToggleFavorito,
    required this.onPostular,
    this.showFullImage = false,
  });

  final Publicacion publicacion;
  final bool esFavorito;
  final bool yaPostulado;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorito;
  final VoidCallback onPostular;
  final bool showFullImage;

  @override
  Widget build(BuildContext context) {
    final desc = publicacion.descripcion;
    final preview = desc.length > 80 ? '${desc.substring(0, 80)}…' : desc;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen/Avatar a la izquierda (más pequeño)
              _buildImage(),
              const SizedBox(width: 12),
              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con título y favorito
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            publicacion.titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleFavorito,
                          icon: Icon(
                            esFavorito ? Icons.favorite : Icons.favorite_border,
                            color: esFavorito ? AppColors.danger : AppColors.textSecondary,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Información compacta
                    if (publicacion.fundacionNombre != null)
                      _CompactInfoRow(
                        Icons.business_outlined,
                        publicacion.fundacionNombre!,
                      ),
                    if (publicacion.municipio != null)
                      _CompactInfoRow(
                        Icons.location_on_outlined,
                        publicacion.municipio!.nombre,
                      ),
                    _CompactInfoRow(
                      Icons.calendar_month_outlined,
                      '${formatShortDate(publicacion.fechaInicio)} – ${formatShortDate(publicacion.fechaFin)}',
                    ),
                    // Chips compactos
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _CompactChip(label: _modalidadLabel(publicacion.modalidad)),
                        if (publicacion.categoriaNombre != null)
                          _CompactChip(
                            label: publicacion.categoriaNombre!,
                            muted: true,
                          ),
                      ],
                    ),
                    // Descripción (solo si hay espacio)
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Botón de acción compacto
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: yaPostulado ? null : onPostular,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              yaPostulado ? 'Postulado' : 'Postularme',
                              style: const TextStyle(fontSize: 12),
                            ),
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
      ),
    );
  }

  Widget _buildImage() {
    if (showFullImage && publicacion.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          publicacion.imageUrls.first,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        ),
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.volunteer_activism,
        color: AppColors.primary,
        size: 28,
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

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.background
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}