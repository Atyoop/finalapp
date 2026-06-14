import 'package:dio/dio.dart';
import '../main.dart';
import 'language_service.dart';

/// Centralized Dio client for the app.
/// Use `ApiClient.setToken(token)` to set Authorization header.
class ApiClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://drugsafe.runasp.net/api',
            headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              try {
                options.headers['Accept-Language'] = LanguageService.currentLanguage;
                options.queryParameters['lang'] = LanguageService.currentLanguage;
              } catch (_) {}
              return handler.next(options);
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
            responseBody: true,
            error: true,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onError: (DioException e, handler) {
              if (e.response?.statusCode == 401) {
                triggerGlobalLogout();
              }
              return handler.next(e);
            },
          ),
        );

  /// Set or clear the Authorization header.
  static void setToken(String? token) {
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }

  /// Attach interceptor that reads token each request via tokenGetter.
  static void addTokenInterceptor(String? Function()? tokenGetter) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            final token = tokenGetter?.call();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              options.headers.remove('Authorization');
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }
}
