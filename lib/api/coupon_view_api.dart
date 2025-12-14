import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'api_client.dart';

class CouponViewApi {
  CouponViewApi(this._apiClient);

  final ApiClient _apiClient;
  static const _baseUrl = AppConstants.couponViewUrl;

  Future<dynamic> getCouponHtml(String email, String hsh) async {
    final params = {'email': email, 'hsh': hsh};

    return await _apiClient.getDio().get(
      _baseUrl,
      queryParameters: params,
      options: Options(
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ),
    );
  }
}
