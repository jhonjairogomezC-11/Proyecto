import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/ranking/data/models/ranking.dart';
import 'package:voluntapp_mobile/features/ranking/data/repositories/ranking_repository.dart';
import 'package:voluntapp_mobile/features/shared/widgets/avatar_image.dart';
import 'package:voluntapp_mobile/features/voluntario/data/repositories/voluntario_repository.dart';

/// Screen 11 — Ranking
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  static const _topOptions = [10, 25, 50];

  RankingResponse? _ranking;
  int _top = 10;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(rankingRepositoryProvider).fetchRanking(top: _top);
      if (!mounted) return;
      setState(() => _ranking = data);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e is ApiException ? e.message : 'Error al cargar ranking.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeTop(int top) async {
    if (_top == top) return;
    setState(() => _top = top);
    await _load();
  }

  bool _isMe(RankingEntry entry, String? voluntarioId) {
    return voluntarioId != null && entry.voluntarioId == voluntarioId;
  }

  @override
  Widget build(BuildContext context) {
    final voluntarioId = ref.watch(voluntarioPerfilProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking de Voluntarios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _topOptions
                            .map(
                              (t) => ChoiceChip(
                                label: Text('Top $t'),
                                selected: _top == t,
                                onSelected: (_) => _changeTop(t),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      if (_ranking!.top.length >= 3)
                        _Podio(top: _ranking!.top.take(3).toList()),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Clasificación',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Chip(
                                    label:
                                        Text('${_ranking!.total} voluntarios'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_ranking!.top.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'Aún no hay voluntarios con puntos acumulados.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              else ...[
                                ..._ranking!.top.map(
                                  (entry) => _RankingRow(
                                    entry: entry,
                                    isMe: _isMe(entry, voluntarioId),
                                  ),
                                ),
                                if (_ranking!
                                    .miPosicionFueraDelTop(voluntarioId)) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      children: [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            'Tu posición',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                  ),
                                  _RankingRow(
                                    entry: _ranking!.miPosicion!,
                                    isMe: true,
                                    highlight: true,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Podio extends StatelessWidget {
  const _Podio({required this.top});

  final List<RankingEntry> top;

  @override
  Widget build(BuildContext context) {
    final first = top[0];
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(child: _PodioItem(entry: second, place: 2, height: 100)),
          Expanded(
              child: _PodioItem(
                  entry: first, place: 1, height: 130, isFirst: true)),
          if (third != null)
            Expanded(child: _PodioItem(entry: third, place: 3, height: 80)),
        ],
      ),
    );
  }
}

class _PodioItem extends StatelessWidget {
  const _PodioItem({
    required this.entry,
    required this.place,
    required this.height,
    this.isFirst = false,
  });

  final RankingEntry entry;
  final int place;
  final double height;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colors = switch (place) {
      1 => (const Color(0xFFF59E0B), const Color(0xFFEA580C)),
      2 => (const Color(0xFF94A3B8), const Color(0xFF64748B)),
      _ => (const Color(0xFFCD7F32), const Color(0xFFA16207)),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
        AvatarImage(
          imageUrl: entry.fotoPerfil,
          fallbackText: entry.nombre,
          radius: isFirst ? 28 : 22,
          backgroundColor: colors.$1,
          textColor: Colors.white,
        ),
        const SizedBox(height: 6),
        Text(
          entry.nombre.split(' ').first,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('${entry.puntos} pts',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.$1, colors.$2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$place°',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.isMe,
    this.highlight = false,
  });

  final RankingEntry entry;
  final bool isMe;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight || isMe
            ? AppColors.primary.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: highlight || isMe
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.posicion}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: entry.posicion <= 3
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ),
          AvatarImage(
            imageUrl: entry.fotoPerfil,
            fallbackText: entry.nombre,
            radius: 18,
            backgroundColor: isMe
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.12),
            textColor: isMe ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tú',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  entry.municipio ?? 'Colombia',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.puntos}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${entry.participaciones} act.',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
