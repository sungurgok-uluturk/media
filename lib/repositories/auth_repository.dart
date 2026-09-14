import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Kimlik Doğrulama Repository
/// 
/// Tüm kimlik doğrulama ve kullanıcı yönetimi işlemlerini yapar.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Özellikleri:
/// - Kayıt işlemleri (yeni üyelik)
/// - Giriş işlemleri
/// - Şifre yönetimi
/// - Profil güncelleme
/// - Oturum yönetimi

class AuthRepository {
  final ApiService _apiService = ApiService();
  static const String _authEndpoint = '/auth';
  static const String _usersEndpoint = '/users';

  /// Yeni kullanıcı kaydı
  /// 
  /// [username]: Kullanıcı adı (benzersiz)
  /// [email]: E-posta adresi (benzersiz)
  /// [password]: Şifre
  /// 
  /// Returns: Başarılı mı?
  /// 
  /// Not: Yeni kullanıcılar 'pending' durumunda oluşturulur.
  /// Admin onayı verilmeden sisteme giriş yapamaz.
  /// 
  /// Örnek:
  /// ```dart
  /// final success = await authRepository.register(
  ///   username: 'john_doe',
  ///   email: 'john@example.com',
  ///   password: 'SecurePassword123',
  /// );
  /// ```
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      return response['success'] == true;
    } on DioException catch (e) {
      print('Kayıt hatası: ${e.message}');
      rethrow;
    }
  }

  /// Giriş yap
  /// 
  /// [username]: Kullanıcı adı veya e-posta
  /// [password]: Şifre
  /// [rememberMe]: Beni hatırla seçeneği
  /// 
  /// Returns: Giriş yapan kullanıcı
  /// 
  /// Hata Durumları:
  /// - Hesap onaylanmamış: 'approval_pending'
  /// - Hesap banlandı: 'account_banned'
  /// - Geçersiz kimlik: 'invalid_credentials'
  /// 
  /// Örnek:
  /// ```dart
  /// final user = await authRepository.login(
  ///   username: 'john_doe',
  ///   password: 'SecurePassword123',
  ///   rememberMe: true,
  /// );
  /// ```
  Future<User?> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/login',
        data: {
          'username': username,
          'password': password,
          'remember_me': rememberMe,
        },
      );

      if (response['success'] == true && response['user'] != null) {
        return User.fromJson(response['user'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      print('Giriş hatası: ${e.message}');
      rethrow;
    }
  }

  /// Çıkış yap
  /// 
  /// [userId]: Çıkış yapan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await authRepository.logout(userId: 'user-123');
  /// ```
  Future<void> logout({required String userId}) async {
    try {
      await _apiService.post(
        '$_authEndpoint/logout',
        data: {'user_id': userId},
      );
    } on DioException catch (e) {
      print('Çıkış hatası: ${e.message}');
      rethrow;
    }
  }

  /// Şifre değiştir
  /// 
  /// [userId]: Kullanıcı ID
  /// [currentPassword]: Mevcut şifre
  /// [newPassword]: Yeni şifre
  /// 
  /// Returns: Başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// final success = await authRepository.changePassword(
  ///   userId: 'user-123',
  ///   currentPassword: 'OldPassword123',
  ///   newPassword: 'NewPassword456',
  /// );
  /// ```
  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/change-password',
        data: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return response['success'] == true;
    } on DioException catch (e) {
      print('Şifre değiştirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı profilini getir
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Returns: Kullanıcı nesnesi
  /// 
  /// Örnek:
  /// ```dart
  /// final user = await authRepository.getProfile(userId: 'user-123');
  /// ```
  Future<User?> getProfile({required String userId}) async {
    try {
      final response = await _apiService.get(
        '$_usersEndpoint?id=eq.$userId',
      );

      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return null;

      return User.fromJson(data[0] as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Profil getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Profili güncelle
  /// 
  /// [userId]: Kullanıcı ID
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Güncellenebilir alanlar:
  /// - phone_number
  /// - avatar_url
  /// - bio
  /// 
  /// Örnek:
  /// ```dart
  /// await authRepository.updateProfile(
  ///   userId: 'user-123',
  ///   updates: {
  ///     'phone_number': '+90 555 123 4567',
  ///     'bio': 'Yeni biyografi',
  ///   },
  /// );
  /// ```
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _apiService.patch(
        '$_usersEndpoint?id=eq.$userId',
        data: updates,
      );
    } on DioException catch (e) {
      print('Profil güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Başarısız giriş denemesini kontrol et (Brute force koruması)
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Returns: Hesap kilitli mi?
  /// 
  /// Örnek:
  /// ```dart
  /// final isLocked = await authRepository.isAccountLocked(userId: 'user-123');
  /// ```
  Future<bool> isAccountLocked({required String userId}) async {
    try {
      final response = await _apiService.get(
        '$_usersEndpoint?id=eq.$userId&select=id,status',
      );

      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return false;

      final status = data[0]['status'] as String?;
      return status == 'banned' || status == 'suspended';
    } on DioException catch (e) {
      print('Hesap kilidi kontrol hatası: ${e.message}');
      return false;
    }
  }

  /// Beni Hatırla token'ını doğrula
  /// 
  /// [userId]: Kullanıcı ID
  /// [token]: Remember me token
  /// 
  /// Returns: Token geçerli mi?
  /// 
  /// Örnek:
  /// ```dart
  /// final isValid = await authRepository.validateRememberMeToken(
  ///   userId: 'user-123',
  ///   token: 'token-string',
  /// );
  /// ```
  Future<bool> validateRememberMeToken({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/validate-token',
        data: {
          'user_id': userId,
          'token': token,
        },
      );

      return response['valid'] == true;
    } on DioException catch (e) {
      print('Token doğrulama hatası: ${e.message}');
      return false;
    }
  }

  /// Beni Hatırla otomatik giriş
  /// 
  /// [userId]: Kullanıcı ID
  /// [token]: Remember me token
  /// 
  /// Returns: Giriş yapan kullanıcı
  /// 
  /// Örnek:
  /// ```dart
  /// final user = await authRepository.autoLogin(
  ///   userId: 'user-123',
  ///   token: 'token-string',
  /// );
  /// ```
  Future<User?> autoLogin({
    required String userId,
    required String token,
  }) async {
    try {
      final isValid = await validateRememberMeToken(
        userId: userId,
        token: token,
      );

      if (!isValid) return null;

      return getProfile(userId: userId);
    } catch (e) {
      print('Otomatik giriş hatası: $e');
      return null;
    }
  }

  /// E-posta doğrulaması için kod gönder (ileriki versiyonlar için)
  /// 
  /// [email]: E-posta adresi
  /// 
  /// Returns: Başarılı mı?
  Future<bool> sendEmailVerificationCode({required String email}) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/send-verification-code',
        data: {'email': email},
      );

      return response['success'] == true;
    } on DioException catch (e) {
      print('Doğrulama kodu gönderme hatası: ${e.message}');
      rethrow;
    }
  }

  /// E-posta doğrulama kodunu kontrol et (ileriki versiyonlar için)
  /// 
  /// [email]: E-posta adresi
  /// [code]: Doğrulama kodu
  /// 
  /// Returns: Kod doğru mu?
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        '$_authEndpoint/verify-email-code',
        data: {
          'email': email,
          'code': code,
        },
      );

      return response['valid'] == true;
    } on DioException catch (e) {
      print('E-posta doğrulama hatası: ${e.message}');
      rethrow;
    }
  }
}
