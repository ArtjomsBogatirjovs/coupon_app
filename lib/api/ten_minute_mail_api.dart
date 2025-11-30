import 'dart:io';

import 'package:coupon_app/api/api_client.dart';
import 'package:coupon_app/core/constants.dart';
import 'package:dio/dio.dart';

import '../models/temp_mail_address_response.dart';
import '../models/temp_mail_inbox_response.dart';

class TenMinuteMailApi {
  TenMinuteMailApi(this._apiClient);

  final ApiClient _apiClient;
  static const _baseUrl = AppConstants.tenMinuteMailBaseUrl;

  Future<List<TempMailInboxResponse>> getInbox(String cookieHeader) async {
    final res = await _apiClient.getDio().get(
      '$_baseUrl/messages/messagesAfter/0',
      options: Options(headers: {HttpHeaders.cookieHeader: cookieHeader}),
    );
    final data = res.data;
    if (data == null || data is! List) {
      return <TempMailInboxResponse>[];
    }
    return (data)
        .map((e) => TempMailInboxResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TempMailAddressResponse> createNewAddress() async {
    await deleteCookies();
    final res = await _apiClient.getDio().get('$_baseUrl/session/address');
    return TempMailAddressResponse.fromJson(res.data);
  }

  Future<List<Cookie>> getCookies() async {
    return await _apiClient.getCookies(_baseUrl);
  }

  Future<void> deleteCookies() async {
    return await _apiClient.deleteCookies(_baseUrl);
  }
}
