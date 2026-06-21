import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/ranking/data/models/ranking.dart';

class RankingRepository {
  RankingRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<RankingResponse> fetchRanking({int top = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.ranking,
        queryParameters: {'top': top},
      );
      return RankingResponse.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref);
});
