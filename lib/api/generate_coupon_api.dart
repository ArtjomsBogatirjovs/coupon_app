import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'api_client.dart';

class GenerateCouponApi {
  GenerateCouponApi(this._apiClient);

  final ApiClient _apiClient;
  static const _baseUrl = AppConstants.couponUrl;

  Future<void> generateCoupon(String email) async {
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
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.data}');
  }
}
