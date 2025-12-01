import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';

class ApiClient {
  final Dio _dio;
  final PersistCookieJar _cookieJar;

  ApiClient._(this._dio, this._cookieJar);

  static Future<ApiClient> create() async {
    final options = BaseOptions(
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {HttpHeaders.acceptHeader: 'application/json'},
    );

    final dio = Dio(options);

    final dir = await getApplicationDocumentsDirectory();
    final jar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));

    dio.interceptors.add(CookieManager(jar));

    return ApiClient._(dio, jar);
  }

  Dio getDio() {
    return _dio;
  }

  Future<List<Cookie>> getCookies(String url) async {
    return await _cookieJar.loadForRequest(Uri.parse(url));
  }

  Future<void> deleteCookies(String url) async {
    return await _cookieJar.delete(Uri.parse(url));
  }
}
