import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Kimlik Doğrulama Provider
/// 
/// Uygulamanın tüm kimlik doğrulama işlemlerini yönetir.
/// Giriş, çıkış, kayıt vb.
/// 
/// State Management: Provider kullanılır
/// Dinleyiciler: UI'daki değişiklikleri takip eder

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Giriş yapmış kullanıcı
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => _currentUser != null;

  /// Kullanıcı yönetici mi?
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Kayıt ol
  /// 
  /// [username]: Kullanıcı adı
  /// [email]: E-posta adresi
  /// [password]: Şifre
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Not: Yeni kullanıcılar 'pending' durumunda oluşturulur ve admin onayı bekler.
  /// Onay verilmeden sisteme giriş yapamaz.
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response['success'] == true) {
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Kayıt işlemi başarısız';
        return false;
      }
    } catch (e) {
      _error = 'Kayıt işlemi sırasında hata: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Giriş yap
  /// 
  /// [username]: Kullanıcı adı veya e-posta
  /// [password]: Şifre
  /// [rememberMe]: Beni hatırla seçeneği
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Hata Durumları:
  /// - Hesap onaylanmamış: 'approval_pending'
  /// - Hesap banlandı: 'account_banned'
  /// - Yanlış şifre: 'invalid_credentials'
  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'remember_me': rememberMe,
        },
      );

      if (response['success'] == true) {
        // Giriş başarılı - kullanıcı bilgisini kaydet
        _currentUser = User.fromJson(response['user'] as Map<String, dynamic>);
        _error = null;
        return true;
      } else {
        // Giriş başarısız
        _error = response['message'] ?? 'Giriş işlemi başarısız';
        return false;
      }
    } catch (e) {
      _error = 'Giriş işlemi sırasında hata: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Çıkış yap
  /// 
  /// Örnek:
  /// ```dart
  /// await authProvider.logout();
  /// ```
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.post(
        '/auth/logout',
        data: {'user_id': _currentUser?.id},
      );
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Çıkış işlemi sırasında hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Şifre değiştir
  /// 
  /// [currentPassword]: Mevcut şifre
  /// [newPassword]: Yeni şifre
  /// 
  /// Returns: İşlem başarılı mı?
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/change-password',
        data: {
          'user_id': _currentUser?.id,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return response['success'] == true;
    } catch (e) {
      _error = 'Şifre değiştirme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mevcut kullanıcı bilgisini güncelle
  /// 
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Örnek:
  /// ```dart
  /// await authProvider.updateProfile({
  ///   'phone_number': '+90 555 123 4567',
  ///   'bio': 'Yeni bio',
  /// });
  /// ```
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/users/${_currentUser?.id}',
        data: updates,
      );

      if (response['success'] == true) {
        // Kullanıcı bilgisini güncelle
        final updatedUser = _currentUser?.copyWith(
          phoneNumber: updates['phone_number'],
          bio: updates['bio'],
          // Diğer alanlar...
        );
        _currentUser = updatedUser;
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Profil güncelleme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
