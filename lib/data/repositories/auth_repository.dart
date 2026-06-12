import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../auth/alpha_auth_session.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatar;
  final int balance;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar,
    this.balance = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ??
              json['id'] ??
              json['userId'] ??
              json['uid'] ??
              json['email'] ??
              '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['name'] ?? json['displayName'])?.toString(),
      avatar: (json['avatar'] ?? json['photoUrl'] ?? json['photo'])?.toString(),
      balance: json['balance'] ?? 0,
    );
  }

  static AppUser? fromAuthResponse(Map<String, dynamic> response) {
    final data = response['data'];
    final userData = data is Map && data['user'] is Map ? data['user'] : data;
    if (userData is! Map) {
      return null;
    }
    final user = AppUser.fromJson(Map<String, dynamic>.from(userData));
    AlphaAuthSession().setUser(
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
    );
    return user;
  }
}

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<void> setToken(String token) => _apiClient.setToken(token);

  Future<String?> getToken() => _apiClient.getToken();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];

        if (token != null) {
          await _apiClient.setToken(token);
        }
        return response.data;
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Login failed'
      };
    } on DioException catch (e) {
      debugPrint('AuthRepository.login DioException: $e');
      final message = e.response?.data is Map 
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Sai email hoặc mật khẩu')
          : 'Đăng nhập thất bại';
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('AuthRepository.login error: $e');
      return {'success': false, 'message': 'Đã có lỗi xảy ra. Vui lòng thử lại.'};
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];

        if (token != null) {
          await _apiClient.setToken(token);
        }
        return response.data;
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Registration failed'
      };
    } on DioException catch (e) {
      debugPrint('AuthRepository.register DioException: $e');
      final message = e.response?.data is Map 
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Đăng ký thất bại')
          : 'Đăng ký thất bại';
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('AuthRepository.register error: $e');
      return {'success': false, 'message': 'Đã có lỗi xảy ra. Vui lòng thử lại.'};
    }
  }

  Future<AppUser?> getMe() async {
    try {
      final token = await _apiClient.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _apiClient.dio.get('/auth/me');

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final userData =
            data is Map && data['user'] is Map ? data['user'] : data;
        if (userData is! Map) {
          return null;
        }
        final user = AppUser.fromJson(Map<String, dynamic>.from(userData));
        AlphaAuthSession().setUser(
          userId: user.id,
          email: user.email,
          displayName: user.displayName,
        );
        return user;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      debugPrint('AuthRepository.getMe error: $e');
      return null;
    } catch (e) {
      debugPrint('AuthRepository.getMe error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _apiClient.clearToken();
      AlphaAuthSession().clear();
    }
  }
}
