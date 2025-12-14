import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import 'api_client.dart';

class CouponViewApi {
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.api,
    source: 'CouponApi',
  );
  static const _baseUrl = AppConstants.couponViewUrl;

  final ApiClient _apiClient;

  CouponViewApi(this._apiClient);

  Future<Response<dynamic>> getCouponHtml(
    String email,
    String hsh,
    String chainId,
  ) async {
    final params = {'email': email, 'hsh': hsh};

    await _log.info(
      'Requesting coupon HTML',
      chainId: chainId,
      extra: {'email': email, 'endpoint': _baseUrl},
    );

    try {
      final response = await _apiClient.getDio().get(
        _baseUrl,
        queryParameters: params,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
          validateStatus: (_) => true,
        ),
      );

      await _log.debug(
        'Coupon HTML response received',
        chainId: chainId,
        extra: {
          'statusCode': response.statusCode,
          'contentLength': response.data?.toString().length,
        },
      );

      return response;
    } catch (e, s) {
      final error = NetworkError(
        message: 'Failed to load coupon HTML',
        detail: 'GET $_baseUrl',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);

      rethrow;
    }
  }
}
