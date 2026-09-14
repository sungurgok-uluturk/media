import 'package:flutter/material.dart';
import '../repositories/admin_repository.dart';

/// Yönetici Provider
/// 
/// Tüm yönetici işlemlerini yönetir.
/// Kullanıcı yönetimi, raporlar, loglar vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikler:
/// - Kullanıcı listeleme ve yönetimi
/// - Rapor yönetimi
/// - Yönetici ve kullanıcı logları
/// - Sistem ayarları
/// - Bakım modu
/// 
/// NOT: Sadece yönetici erişimi!

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository = AdminRepository();

  // Kullanıcı Yönetimi
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  Map<String, dynamic>? _selectedUserProfile;
  Map<String, dynamic>? get selectedUserProfile => _selectedUserProfile;

  // Rapor Yönetimi
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  // Loglar
  List<Map<String, dynamic>> _adminLogs = [];
  List<Map<String, dynamic>> get adminLogs => _adminLogs;

  List<Map<String, dynamic>> _userLogs = [];
  List<Map<String, dynamic>> get userLogs => _userLogs;

  // Sistem
  Map<String, dynamic>? _systemStats;
  Map<String, dynamic>? get systemStats => _systemStats;

  Map<String, dynamic>? _appConfig;
  Map<String, dynamic>? get appConfig => _appConfig;

  bool _maintenanceMode = false;
  bool get maintenanceMode => _maintenanceMode;

  // State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  String _userStatusFilter = 'approved'; // approved, pending, banned
  String get userStatusFilter => _userStatusFilter;

  String _reportStatusFilter = 'pending'; // pending, resolved, not_resolved
  String get reportStatusFilter => _reportStatusFilter;

  // ============ KULLANICI YÖNETİMİ ============

  /// Tüm kullanıcıları yükle
  /// 
  /// [status]: Durum filtresi
  /// [limit]: Limit
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadUsers(status: 'pending');
  /// ```
  Future<void> loadUsers({
    String status = 'approved',
    int limit = 30,
  }) async {
    _userStatusFilter = status;
    _currentPage = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminRepository.getAllUsers(
        status: status,
        limit: limit,
        offset: 0,
      );
      _error = null;
    } catch (e) {
      _error = 'Kullanıcıları yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı profilini yükle
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadUserProfile('user-123');
  /// ```
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUserProfile = await _adminRepository.getUserProfile(userId);
      _error = null;
    } catch (e) {
      _error = 'Kullanıcı profilini yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcıyı onayla
  /// 
  /// [userId]: Onaylanacak kullanıcı ID
  /// [adminId]: Onaylayan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.approveUser(
  ///   userId: 'user-123',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> approveUser({
    required String userId,
    required String adminId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _adminRepository.approveUser(
        userId: userId,
        adminId: adminId,
      );
      if (success) {
        // Listeden güncellemeleri yeniden yükle
        await loadUsers();
      }
      return success;
    } catch (e) {
      _error = 'Onaylama hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı seviyesini değiştir
  /// 
  /// [userId]: Kullanıcı ID
  /// [newTier]: Yeni seviye
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.changeUserTier(
  ///   userId: 'user-123',
  ///   newTier: 'gold',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> changeUserTier({
    required String userId,
    required String newTier,
    required String adminId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _adminRepository.changeUserTier(
        userId: userId,
        newTier: newTier,
        adminId: adminId,
      );
    } catch (e) {
      _error = 'Seviye değiştirme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcıyı banla
  /// 
  /// [userId]: Banlanacak kullanıcı ID
  /// [reason]: Sebep
  /// [duration]: Süre (null = kalıcı)
  /// [scope]: Kapsam
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.banUser(
  ///   userId: 'user-123',
  ///   reason: 'Spam',
  ///   duration: Duration(days: 7),
  ///   scope: 'system',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> banUser({
    required String userId,
    required String reason,
    Duration? duration,
    required String scope,
    required String adminId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _adminRepository.banUser(
        userId: userId,
        reason: reason,
        duration: duration,
        scope: scope,
        adminId: adminId,
      );
      if (success) {
        await loadUsers(status: 'banned');
      }
      return success;
    } catch (e) {
      _error = 'Ban hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı banını kaldır
  /// 
  /// [userId]: Ban kaldırılacak kullanıcı ID
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.unbanUser(
  ///   userId: 'user-123',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> unbanUser({
    required String userId,
    required String adminId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _adminRepository.unbanUser(
        userId: userId,
        adminId: adminId,
      );
    } catch (e) {
      _error = 'Ban kaldırma hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ RAPORLAMA SİSTEMİ ============

  /// Raporları yükle
  /// 
  /// [status]: Durum filtresi
  /// [reportType]: Rapor türü
  /// [limit]: Limit
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadReports(
  ///   status: 'pending',
  ///   reportType: 'tv',
  /// );
  /// ```
  Future<void> loadReports({
    String status = 'pending',
    String? reportType,
    int limit = 50,
  }) async {
    _reportStatusFilter = status;
    _currentPage = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _adminRepository.getAllReports(
        status: status,
        reportType: reportType,
        limit: limit,
        offset: 0,
      );
      _error = null;
    } catch (e) {
      _error = 'Raporları yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Raporu çöz
  /// 
  /// [reportId]: Rapor ID
  /// [resolved]: Çözüldü mü?
  /// [resolutionNotes]: Çözüm notları
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.resolveReport(
  ///   reportId: 1,
  ///   resolved: true,
  ///   resolutionNotes: 'Link düzeltildi',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> resolveReport({
    required int reportId,
    required bool resolved,
    String? resolutionNotes,
    required String adminId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _adminRepository.resolveReport(
        reportId: reportId,
        resolved: resolved,
        resolutionNotes: resolutionNotes,
        adminId: adminId,
      );
      if (success) {
        // Raporları yeniden yükle
        await loadReports();
      }
      return success;
    } catch (e) {
      _error = 'Rapor çözme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ LOGLAR ============

  /// Yönetici loglarını yükle
  /// 
  /// [adminId]: Yönetici ID (opsiyonel)
  /// [limit]: Limit
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadAdminLogs(limit: 100);
  /// ```
  Future<void> loadAdminLogs({
    String? adminId,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminLogs = await _adminRepository.getAdminLogs(
        adminId: adminId,
        limit: limit,
        offset: 0,
      );
      _error = null;
    } catch (e) {
      _error = 'Yönetici loglarını yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı loglarını yükle
  /// 
  /// [userId]: Kullanıcı ID
  /// [limit]: Limit
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadUserLogs(userId: 'user-123', limit: 50);
  /// ```
  Future<void> loadUserLogs({
    required String userId,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userLogs = await _adminRepository.getUserLogs(
        userId: userId,
        limit: limit,
        offset: 0,
      );
      _error = null;
    } catch (e) {
      _error = 'Kullanıcı loglarını yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ SİSTEM AYARLARI ============

  /// Sistem istatistiklerini yükle
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadSystemStats();
  /// ```
  Future<void> loadSystemStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _systemStats = await _adminRepository.getSystemStats();
      _error = null;
    } catch (e) {
      _error = 'Sistem istatistiklerini yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uygulama yapılandırmasını yükle
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.loadAppConfig();
  /// ```
  Future<void> loadAppConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appConfig = await _adminRepository.getAppConfig();
      _maintenanceMode = _appConfig?['maintenance_mode'] ?? false;
      _error = null;
    } catch (e) {
      _error = 'Uygulama yapılandırmasını yüklerken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bakım modunu aç/kapat
  /// 
  /// [enabled]: Bakım modu açılsın mı?
  /// [message]: Bakım mesajı
  /// [rootId]: Root yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.setMaintenanceMode(
  ///   enabled: true,
  ///   message: 'Sistem bakımda',
  ///   rootId: 'root-789',
  /// );
  /// ```
  Future<bool> setMaintenanceMode({
    required bool enabled,
    String? message,
    required String rootId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _adminRepository.setMaintenanceMode(
        enabled: enabled,
        message: message,
        rootId: rootId,
      );
      if (success) {
        _maintenanceMode = enabled;
      }
      return success;
    } catch (e) {
      _error = 'Bakım modu ayarlama hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uygulama yapılandırmasını güncelle
  /// 
  /// [config]: Yapılandırma verileri
  /// [rootId]: Root yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminProvider.updateAppConfig(
  ///   config: {
  ///     'telegram_channel_url': 'https://t.me/newchannel',
  ///   },
  ///   rootId: 'root-789',
  /// );
  /// ```
  Future<bool> updateAppConfig({
    required Map<String, dynamic> config,
    required String rootId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _adminRepository.updateAppConfig(
        config: config,
        rootId: rootId,
      );
      if (success) {
        await loadAppConfig();
      }
      return success;
    } catch (e) {
      _error = 'Yapılandırma güncelleme hatası: $e';
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

  /// Tüm veriyi sıfırla
  void reset() {
    _users = [];
    _selectedUserProfile = null;
    _reports = [];
    _adminLogs = [];
    _userLogs = [];
    _systemStats = null;
    _appConfig = null;
    _maintenanceMode = false;
    _currentPage = 0;
    _error = null;
    notifyListeners();
  }
}
