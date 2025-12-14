import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import 'api_client.dart';

class GenerateCouponApi {
  static const _baseUrl = AppConstants.couponUrl;
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.api,
    source: 'GenerateCouponApi',
  );
  final ApiClient _apiClient;

  GenerateCouponApi(this._apiClient);

  Future<void> generateCoupon(String email, String chainId) async {
    await _log.info(
      'Sending coupon generation request',
      chainId: chainId,
      details: 'POST $_baseUrl',
      extra: {'email': email},
    );

    try {
      final params = {'isAjax': '1'};
      final body = {'EMAIL': email, 'email_address_check': '', 'locale': 'en'};

      final response = await _apiClient.getDio().post(
        _baseUrl,
        queryParameters: params,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (_) => true,
        ),
      );

      await _log.debug(
        'Coupon generation request sent',
        chainId: chainId,
        details: 'response',
        extra: {
          'statusCode': response.statusCode,
          'body': response.data.toString(),
        },
      );
    } catch (e, st) {
      final error = ApiError(
        message: 'Failed to send coupon request',
        detail: 'POST $_baseUrl',
        cause: e,
        stackTrace: st,
      );

      await _log.errorFrom(error, chainId: chainId, extra: {'email': email});

      rethrow;
    }
  }
}
