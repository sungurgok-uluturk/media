import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/admin_repository.dart';

/// Admin Provider
/// 
/// Yönetim paneli işlemlerini yönetir.
/// Kullanıcı yönetimi, Rapor yönetimi, Bildirim yönetimi vb.
/// 
/// State Management: Provider kullanılır

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository = AdminRepository();

  /// Tüm kullanıcılar
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  /// Raporlar
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  /// Yönetici logları
  List<Map<String, dynamic>> _adminLogs = [];
  List<Map<String, dynamic>> get adminLogs => _adminLogs;

  /// Kullanıcı logları
  List<Map<String, dynamic>> _userLogs = [];
  List<Map<String, dynamic>> get userLogs => _userLogs;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Tüm kullanıcıları yükle
  /// 
  /// [status]: Durum filtresi (pending, approved, banned)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadUsers(status: 'pending');
  /// ```
  Future<void> loadUsers({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminRepository.getAllUsers(status: status);
      _error = null;
    } catch (e) {
      _error = 'Kullanıcılar yüklenirken hata: $e';
      print('Load users error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcıyı onayla
  /// 
  /// [userId]: Onaylanacak kullanıcı ID
  /// [adminId]: Onaylayan admin ID
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.approveUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  /// );
  /// ```
  Future<bool> approveUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      await _adminRepository.approveUser(
        userId: userId,
        adminId: adminId,
      );

      // Listenin güncellemesini sağla
      await loadUsers(status: 'pending');
      return true;
    } catch (e) {
      _error = 'Kullanıcı onaylama hatası: $e';
      print('Approve user error: $e');
      return false;
    }
  }

  /// Kullanıcıyı banla
  /// 
  /// [userId]: Banlanacak kullanıcı ID
  /// [reason]: Ban sebebi
  /// [duration]: Ban süresi (dakika cinsinden, null = kalıcı)
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.banUser(
  ///   userId: 'user-id',
  ///   reason: 'Spam',
  ///   duration: 1440,
  /// );
  /// ```
  Future<bool> banUser({
    required String userId,
    required String reason,
    int? duration,
  }) async {
    try {
      await _adminRepository.banUser(
        userId: userId,
        reason: reason,
        duration: duration,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _error = 'Kullanıcı ban etme hatası: $e';
      print('Ban user error: $e');
      return false;
    }
  }

  /// Kullanıcı banlamasını kaldır
  /// 
  /// [userId]: Banlaması kaldırılacak kullanıcı ID
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.unbanUser(userId: 'user-id');
  /// ```
  Future<bool> unbanUser({required String userId}) async {
    try {
      await _adminRepository.unbanUser(userId: userId);
      await loadUsers();
      return true;
    } catch (e) {
      _error = 'Ban kaldırma hatası: $e';
      print('Unban user error: $e');
      return false;
    }
  }

  /// Raporları yükle
  /// 
  /// [status]: Durum filtresi (pending, resolved, not_resolved)
  /// [type]: Tür filtresi (tv, radio, movie, user)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadReports(status: 'pending');
  /// ```
  Future<void> loadReports({
    String? status,
    String? type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _adminRepository.getReports(
        status: status,
        type: type,
      );
      _error = null;
    } catch (e) {
      _error = 'Raporlar yüklenirken hata: $e';
      print('Load reports error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Raporu işle
  /// 
  /// [reportId]: Rapor ID
  /// [status]: Yeni durum (resolved, not_resolved)
  /// [notes]: Çözüm notları
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.processReport(
  ///   reportId: 1,
  ///   status: 'resolved',
  ///   notes: 'Sorun giderildi',
  /// );
  /// ```
  Future<bool> processReport({
    required int reportId,
    required String status,
    String? notes,
  }) async {
    try {
      await _adminRepository.processReport(
        reportId: reportId,
        status: status,
        notes: notes,
      );
      await loadReports();
      return true;
    } catch (e) {
      _error = 'Rapor işleme hatası: $e';
      print('Process report error: $e');
      return false;
    }
  }

  /// Bildirim ekle
  /// 
  /// [title]: Bildirim başlığı
  /// [content]: Bildirim içeriği
  /// [repeatType]: Tekrarlama türü
  /// [adminId]: Yönetici ID
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.addNotification(
  ///   title: 'Güncelleme',
  ///   content: 'Yeni versiyon çıktı',
  ///   adminId: 'admin-id',
  /// );
  /// ```
  Future<bool> addNotification({
    required String title,
    required String content,
    String repeatType = 'once',
    int? repeatLimit,
    required String adminId,
  }) async {
    try {
      await _adminRepository.addNotification(
        title: title,
        content: content,
        repeatType: repeatType,
        repeatLimit: repeatLimit,
        adminId: adminId,
      );
      return true;
    } catch (e) {
      _error = 'Bildirim ekleme hatası: $e';
      print('Add notification error: $e');
      return false;
    }
  }

  /// Bakım modunu etkinle/devre dışı bırak
  /// 
  /// [isEnabled]: Etkinleştirilsin mi?
  /// [message]: Bakım mesajı
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.setMaintenanceMode(
  ///   isEnabled: true,
  ///   message: 'Bakımda...',
  /// );
  /// ```
  Future<bool> setMaintenanceMode({
    required bool isEnabled,
    String? message,
  }) async {
    try {
      await _adminRepository.setMaintenanceMode(
        isEnabled: isEnabled,
        message: message,
      );
      return true;
    } catch (e) {
      _error = 'Bakım modu ayarlama hatası: $e';
      print('Set maintenance mode error: $e');
      return false;
    }
  }

  /// Yönetici loglarını yükle
  /// 
  /// [adminId]: Yönetici ID (opsiyonel)
  /// [actionType]: İşlem türü (opsiyonel)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadAdminLogs(adminId: 'admin-id');
  /// ```
  Future<void> loadAdminLogs({
    String? adminId,
    String? actionType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminLogs = await _adminRepository.getAdminLogs(
        adminId: adminId,
        actionType: actionType,
      );
      _error = null;
    } catch (e) {
      _error = 'Yönetici logları yüklenirken hata: $e';
      print('Load admin logs error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı loglarını yükle
  /// 
  /// [userId]: Kullanıcı ID
  /// [actionType]: İşlem türü (opsiyonel)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadUserLogs(userId: 'user-id');
  /// ```
  Future<void> loadUserLogs({
    required String userId,
    String? actionType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userLogs = await _adminRepository.getUserLogs(
        userId: userId,
        actionType: actionType,
      );
      _error = null;
    } catch (e) {
      _error = 'Kullanıcı logları yüklenirken hata: $e';
      print('Load user logs error: $e');
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
