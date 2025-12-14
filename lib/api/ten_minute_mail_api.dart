import 'dart:io';

import 'package:coupon_app/api/api_client.dart';
import 'package:coupon_app/core/constants.dart';
import 'package:dio/dio.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import '../models/temp_mail_address_response.dart';
import '../models/temp_mail_inbox_response.dart';

class TenMinuteMailApi {
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.api,
    source: 'TenMinuteMailApi',
  );

  static const _baseUrl = AppConstants.tenMinuteMailBaseUrl;

  final ApiClient _apiClient;

  TenMinuteMailApi(this._apiClient);

  Future<List<TempMailInboxResponse>> getInbox(
    String cookieHeader, {
    required String chainId,
  }) async {
    await _log.info(
      'Requesting inbox messages',
      chainId: chainId,
      details: '$_baseUrl/messages/messagesAfter/0',
    );

    try {
      final res = await _apiClient.getDio().get(
        '$_baseUrl/messages/messagesAfter/0',
        options: Options(headers: {HttpHeaders.cookieHeader: cookieHeader}),
      );

      await _log.debug(
        'Inbox response received',
        chainId: chainId,
        extra: {
          'statusCode': res.statusCode,
          'rawType': res.data.runtimeType.toString(),
        },
      );

      final data = res.data;

      if (data == null || data is! List) {
        await _log.warning(
          'Inbox response data invalid or empty',
          chainId: chainId,
          details: 'Expected List, got ${data?.runtimeType}',
        );
        return <TempMailInboxResponse>[];
      }

      final list = data
          .map((e) => TempMailInboxResponse.fromJson(e as Map<String, dynamic>))
          .toList();

      await _log.info('Parsed ${list.length} inbox messages', chainId: chainId);

      return list;
    } catch (e, st) {
      final statusCode = (e is DioException) ? e.response?.statusCode : null;
      final error = NetworkError(
        message: 'Failed to fetch inbox messages',
        detail: '$_baseUrl/messages/messagesAfter/0',
        cause: e,
        stackTrace: st,
        statusCode: statusCode,
      );

      await _log.errorFrom(
        error,
        chainId: chainId,
        extra: {
          'cookieHeader': cookieHeader,
          'statusCode': statusCode,
          'error': e.toString(),
        },
      );

      rethrow;
    }
  }

  Future<TempMailAddressResponse> createNewAddress(String chainId) async {
    try {
      await deleteCookies();

      await _log.info(
        'Starting request for a new temporary email address',
        chainId: chainId,
        details: '$_baseUrl/session/address',
      );

      final res = await _apiClient.getDio().get('$_baseUrl/session/address');

      await _log.debug(
        'HTTP response received',
        chainId: chainId,
        details: '$_baseUrl/session/address',
        extra: {'statusCode': res.statusCode},
      );

      final parsed = TempMailAddressResponse.fromJson(res.data);

      await _log.info(
        'Temporary email address created: ${parsed.address}',
        chainId: chainId,
        details: '$_baseUrl/session/address',
      );

      return parsed;
    } catch (e, st) {
      final error = NetworkError(
        message: 'Failed to request new temporary email address',
        detail: '$_baseUrl/session/address',
        cause: e,
        stackTrace: st,
      );

      await _log.errorFrom(
        error,
        chainId: chainId,
        extra: {'exception': e.toString()},
      );

      rethrow;
    }
  }

  Future<List<Cookie>> getCookies() async {
    return await _apiClient.getCookies(_baseUrl);
  }

  Future<void> deleteCookies() async {
    return await _apiClient.deleteCookies(_baseUrl);
  }
}
