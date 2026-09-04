import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final Dio dio;

  // Use 10.0.2.2 for Android emulator to access localhost, or your computer's local IP if testing on real device
  // Change this to your exact backend URL when deployed!
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Request interceptor to attach Firebase token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        print('API Error: ${e.message}');
        return handler.next(e);
      }
    ));
  }
}
