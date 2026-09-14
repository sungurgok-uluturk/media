import 'package:dio/dio.dart';
import '../services/api_service.dart';

/// Admin Repository
/// 
/// Yönetim paneli işlemlerini yönetir.
/// Kullanıcı yönetimi, İçerik yönetimi, Rapor yönetimi vb.
/// 
/// Bu repository:
/// - Kullanıcıları yönetir
/// - İçerikleri yönetir
/// - Raporları yönetir
/// - Logları gösterir

class AdminRepository {
  final ApiService _apiService = ApiService();
  static const String _usersEndpoint = '/users';
  static const String _reportsEndpoint = '/reports';
  static const String _adminLogsEndpoint = '/admin-logs';
  static const String _userLogsEndpoint = '/user-logs';
  static const String _notificationsEndpoint = '/notifications';

  /// Tüm kullanıcıları getir
  /// 
  /// [status]: Durum filtresi (pending, approved, banned)
  /// [limit]: Kaç kullanıcı getirileceği
  /// [offset]: Kaç kullanıcı atlanacağı
  /// 
  /// Returns: Kullanıcı listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final users = await adminRepository.getAllUsers(status: 'pending');
  /// ```
  Future<List<Map<String, dynamic>>> getAllUsers({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        'order': 'created_at.desc',
      };

      if (status != null) {
        queryParams['status'] = 'eq.$status';
      }

      final response = await _apiService.get(
        _usersEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Kullanıcılar getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı üyünı güncelle (Yönetici)
  /// 
  /// [userId]: Kullanıcı ID
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.updateUser(
  ///   userId: 'user-id',
  ///   updates: {'status': 'approved', 'user_tier': 'vip'},
  /// );
  /// ```
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _apiService.patch(
        '$_usersEndpoint?id=eq.$userId',
        data: updates,
      );
    } on DioException catch (e) {
      print('Kullanıcı güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı onayla (Yönetici)
  /// 
  /// [userId]: Onaylanacak kullanıcı ID
  /// [adminId]: Onaylayan admin ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.approveUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  /// );
  /// ```
  Future<void> approveUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      await _apiService.patch(
        '$_usersEndpoint?id=eq.$userId',
        data: {
          'status': 'approved',
          'approval_status': true,
          'approved_by': adminId,
          'approved_at': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      print('Kullanıcı onaylama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı banla (Yönetici)
  /// 
  /// [userId]: Banlanacak kullanıcı ID
  /// [reason]: Ban sebebi
  /// [duration]: Ban süresi (dakika cinsinden, null = kalıcı)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.banUser(
  ///   userId: 'user-id',
  ///   reason: 'Spam ve küfür',
  ///   duration: 1440, // 24 saat
  /// );
  /// ```
  Future<void> banUser({
    required String userId,
    required String reason,
    int? duration,
  }) async {
    try {
      final expiresAt = duration != null
          ? DateTime.now().add(Duration(minutes: duration))
          : null;

      await _apiService.patch(
        '$_usersEndpoint?id=eq.$userId',
        data: {
          'status': 'banned',
          'ban_status': duration != null ? 'temporary' : 'permanent',
          'ban_reason': reason,
          'ban_expires_at': expiresAt?.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      print('Kullanıcı ban etme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı banlamasını kaldır (Yönetici)
  /// 
  /// [userId]: Banlaması kaldırılacak kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.unbanUser(userId: 'user-id');
  /// ```
  Future<void> unbanUser({required String userId}) async {
    try {
      await _apiService.patch(
        '$_usersEndpoint?id=eq.$userId',
        data: {
          'status': 'approved',
          'ban_status': null,
          'ban_reason': null,
          'ban_expires_at': null,
        },
      );
    } on DioException catch (e) {
      print('Ban kaldırma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Raporları getir
  /// 
  /// [status]: Durum filtresi (pending, resolved, not_resolved)
  /// [type]: Tür filtresi (tv, radio, movie, user)
  /// 
  /// Returns: Rapor listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final reports = await adminRepository.getReports(status: 'pending');
  /// ```
  Future<List<Map<String, dynamic>>> getReports({
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        'order': 'created_at.desc',
      };

      if (status != null) {
        queryParams['status'] = 'eq.$status';
      }
      if (type != null) {
        queryParams['report_type'] = 'eq.$type';
      }

      final response = await _apiService.get(
        _reportsEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Raporlar getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Raporu işle (Yönetici)
  /// 
  /// [reportId]: Rapor ID
  /// [status]: Yeni durum (resolved, not_resolved)
  /// [notes]: Çözüm notları
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.processReport(
  ///   reportId: 1,
  ///   status: 'resolved',
  ///   notes: 'İşlem tamamlandı',
  /// );
  /// ```
  Future<void> processReport({
    required int reportId,
    required String status,
    String? notes,
  }) async {
    try {
      await _apiService.patch(
        '$_reportsEndpoint?id=eq.$reportId',
        data: {
          'status': status,
          'resolution_notes': notes,
          'resolved_at': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      print('Rapor işleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yönetici Loglarını getir
  /// 
  /// [adminId]: Yönetici ID (opsiyonel)
  /// [actionType]: İşlem türü (opsiyonel)
  /// 
  /// Returns: Log listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final logs = await adminRepository.getAdminLogs(adminId: 'admin-id');
  /// ```
  Future<List<Map<String, dynamic>>> getAdminLogs({
    String? adminId,
    String? actionType,
    int limit = 100,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'order': 'created_at.desc',
      };

      if (adminId != null) {
        queryParams['admin_id'] = 'eq.$adminId';
      }
      if (actionType != null) {
        queryParams['action_type'] = 'eq.$actionType';
      }

      final response = await _apiService.get(
        _adminLogsEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Yönetici logları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı Loglarını getir
  /// 
  /// [userId]: Kullanıcı ID
  /// [actionType]: İşlem türü (opsiyonel)
  /// 
  /// Returns: Log listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final logs = await adminRepository.getUserLogs(userId: 'user-id');
  /// ```
  Future<List<Map<String, dynamic>>> getUserLogs({
    required String userId,
    String? actionType,
    int limit = 100,
  }) async {
    try {
      final queryParams = {
        'user_id': 'eq.$userId',
        'limit': limit,
        'order': 'created_at.desc',
      };

      if (actionType != null) {
        queryParams['action_type'] = 'eq.$actionType';
      }

      final response = await _apiService.get(
        _userLogsEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Kullanıcı logları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Bildirim ekle (Yönetici)
  /// 
  /// [title]: Bildirim başlığı
  /// [content]: Bildirim içeriği
  /// [repeatType]: Tekrarlama türü (once, every_6_hours, daily_3_days vb)
  /// [repeatLimit]: Kaç defa tekrarlanacak (null = sınırsız)
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.addNotification(
  ///   title: 'Yeni Güncelleme',
  ///   content: 'Uygulama güncellemesi mevcut',
  ///   repeatType: 'once',
  /// );
  /// ```
  Future<void> addNotification({
    required String title,
    required String content,
    String repeatType = 'once',
    int? repeatLimit,
    required String adminId,
  }) async {
    try {
      await _apiService.post(
        _notificationsEndpoint,
        data: {
          'title': title,
          'content': content,
          'repeat_type': repeatType,
          'repeat_limit': repeatLimit,
          'created_by': adminId,
        },
      );
    } on DioException catch (e) {
      print('Bildirim ekleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Bakım modunu etkinle/devre dışı bırak (Root işlemi)
  /// 
  /// [isEnabled]: Etkinleştirilsin mi?
  /// [message]: Bakım mesajı
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.setMaintenanceMode(
  ///   isEnabled: true,
  ///   message: 'Sistem bakımında...',
  /// );
  /// ```
  Future<void> setMaintenanceMode({
    required bool isEnabled,
    String? message,
  }) async {
    try {
      await _apiService.patch(
        '/app-config',
        data: {
          'maintenance_mode': isEnabled,
          'maintenance_message': message,
        },
      );
    } on DioException catch (e) {
      print('Bakım modu ayarlama hatası: ${e.message}');
      rethrow;
    }
  }
}
