import 'package:dio/dio.dart';
import '../services/api_service.dart';

/// Yönetici Repository
/// 
/// Tüm yönetici işlemlerini yönetir.
/// Kullanıcı yönetimi, içerik yönetimi, raporlar, loglar vb.
/// 
/// Özellikler:
/// - Kullanıcı onaylama/banlama
/// - TV, Radyo, Film yönetimi
/// - Raporlama sistemi
/// - Yönetici logları
/// - İzin yönetimi
/// 
/// NOT: Tüm bu işlemler yönetici rolü gerektirir!

class AdminRepository {
  final ApiService _apiService = ApiService();
  static const String _adminEndpoint = '/admin';

  // ============ KULLANICI YÖNETİMİ ============

  /// Tüm kullanıcıları listele
  /// 
  /// [limit]: Limit
  /// [offset]: Offset
  /// [status]: Durum filtresi (approved, pending, banned)
  /// [sortBy]: Sıralama (username, created_at)
  /// 
  /// Örnek:
  /// ```dart
  /// final users = await adminRepository.getAllUsers(
  ///   status: 'pending',
  ///   limit: 50,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 30,
    int offset = 0,
    String? status,
    String sortBy = 'created_at',
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        'order': '$sortBy.desc',
      };
      if (status != null) {
        queryParams['status'] = 'eq.$status';
      }

      final response = await _apiService.get(
        '$_adminEndpoint/users',
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      print('Kullanıcıları listele hataı: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı profili getir (Yönetici görüşü)
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// final userProfile = await adminRepository.getUserProfile('user-123');
  /// ```
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _apiService.get(
        '$_adminEndpoint/users/$userId',
      );

      return response['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      print('Kullanıcı profili getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı onayla (Yönetici işlemi)
  /// 
  /// [userId]: Onaylanacak kullanıcı ID
  /// [adminId]: Onaylayan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.approveUser(
  ///   userId: 'user-123',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> approveUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/users/$userId/approve',
        data: {'approved_by': adminId},
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Kullanıcı onaylama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı grubunu değiştir (Yönetici işlemi)
  /// 
  /// [userId]: Kullanıcı ID
  /// [newTier]: Yeni seviye (yeni_uye, normal, bronz, gold, vip, onursal)
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.changeUserTier(
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
    try {
      final response = await _apiService.patch(
        '$_adminEndpoint/users/$userId/tier',
        data: {'user_tier': newTier},
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Kullanıcı seviyesi değiştime hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı banla (Yönetici işlemi)
  /// 
  /// [userId]: Banlanacak kullanıcı ID
  /// [reason]: Banlanma sebebi
  /// [duration]: Banlanma süresi (null = kalıcı)
  /// [scope]: Ban kapsamı ('system' = tamamen, 'tv', 'movies', 'chat' vb)
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.banUser(
  ///   userId: 'user-123',
  ///   reason: 'Spam ve uygunsuz içerik',
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
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/users/$userId/ban',
        data: {
          'reason': reason,
          'duration': duration?.inSeconds,
          'scope': scope,
          'banned_by': adminId,
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Kullanıcı banlama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı banını kaldır (Yönetici işlemi)
  /// 
  /// [userId]: Ban kaldırılacak kullanıcı ID
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.unbanUser(
  ///   userId: 'user-123',
  ///   adminId: 'admin-456',
  /// );
  /// ```
  Future<bool> unbanUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/users/$userId/unban',
        data: {'unbanned_by': adminId},
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Kullanıcı ban kaldırma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı sil (Root işlemi)
  /// 
  /// [userId]: Silinecek kullanıcı ID
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.deleteUser(
  ///   userId: 'user-123',
  ///   adminId: 'root-789',
  /// );
  /// ```
  Future<bool> deleteUser({
    required String userId,
    required String adminId,
  }) async {
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/users/$userId/delete',
        data: {'deleted_by': adminId},
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Kullanıcı silme hatası: ${e.message}');
      rethrow;
    }
  }

  // ============ RAPORLAMA SİSTEMİ ============

  /// Tüm raporları listele
  /// 
  /// [status]: Durum (pending, resolved, not_resolved)
  /// [reportType]: Rapor türü (tv, radio, movie, user)
  /// [limit]: Limit
  /// [offset]: Offset
  /// 
  /// Örnek:
  /// ```dart
  /// final reports = await adminRepository.getAllReports(
  ///   status: 'pending',
  ///   reportType: 'tv',
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getAllReports({
    String? status,
    String? reportType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        'order': 'created_at.desc',
      };
      if (status != null) queryParams['status'] = 'eq.$status';
      if (reportType != null) queryParams['report_type'] = 'eq.$reportType';

      final response = await _apiService.get(
        '$_adminEndpoint/reports',
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      print('Raporları listele hatası: ${e.message}');
      rethrow;
    }
  }

  /// Raporu çöz (Yönetici işlemi)
  /// 
  /// [reportId]: Rapor ID
  /// [resolved]: Çözüldü mü?
  /// [resolutionNotes]: Çözüm notları
  /// [adminId]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.resolveReport(
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
    try {
      final response = await _apiService.patch(
        '$_adminEndpoint/reports/$reportId',
        data: {
          'status': resolved ? 'resolved' : 'not_resolved',
          'resolution_notes': resolutionNotes,
          'assigned_to': adminId,
          'resolved_at': DateTime.now().toIso8601String(),
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Rapor çözme hatası: ${e.message}');
      rethrow;
    }
  }

  // ============ LOGLAR ============

  /// Yönetici loglarını getir
  /// 
  /// [adminId]: Yönetici ID (opsiyonel, tüm logları getirmek için boş bırak)
  /// [actionType]: İşlem türü filtresi
  /// [limit]: Limit
  /// [offset]: Offset
  /// 
  /// Örnek:
  /// ```dart
  /// final logs = await adminRepository.getAdminLogs(
  ///   adminId: 'admin-456',
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getAdminLogs({
    String? adminId,
    String? actionType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        'order': 'created_at.desc',
      };
      if (adminId != null) queryParams['admin_id'] = 'eq.$adminId';
      if (actionType != null) queryParams['action_type'] = 'eq.$actionType';

      final response = await _apiService.get(
        '$_adminEndpoint/logs/admin',
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      print('Yönetici loglarını getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcı loglarını getir
  /// 
  /// [userId]: Kullanıcı ID
  /// [actionType]: İşlem türü filtresi
  /// [limit]: Limit
  /// [offset]: Offset
  /// 
  /// Örnek:
  /// ```dart
  /// final logs = await adminRepository.getUserLogs(
  ///   userId: 'user-123',
  ///   limit: 50,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> getUserLogs({
    required String userId,
    String? actionType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'user_id': 'eq.$userId',
        'limit': limit,
        'offset': offset,
        'order': 'created_at.desc',
      };
      if (actionType != null) queryParams['action_type'] = 'eq.$actionType';

      final response = await _apiService.get(
        '$_adminEndpoint/logs/users',
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      print('Kullanıcı loglarını getirme hatası: ${e.message}');
      rethrow;
    }
  }

  // ============ YÖNETICI YÖNETİMİ ============

  /// Yönetici ekle (Root işlemi)
  /// 
  /// [userId]: Yönetici yapılacak kullanıcı ID
  /// [role]: Yönetici rolü (admin, editor, moderator)
  /// [addedBy]: Eklemeyi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.addAdmin(
  ///   userId: 'user-123',
  ///   role: 'moderator',
  ///   addedBy: 'root-789',
  /// );
  /// ```
  Future<bool> addAdmin({
    required String userId,
    required String role,
    required String addedBy,
  }) async {
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/admins',
        data: {
          'user_id': userId,
          'role': role,
          'added_by': addedBy,
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Yönetici ekleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yönetici izinlerini değiştir (Root işlemi)
  /// 
  /// [adminId]: Yönetici ID
  /// [permissions]: Yeni izinler
  /// [changedBy]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.updateAdminPermissions(
  ///   adminId: 'admin-456',
  ///   permissions: {
  ///     'tv': {'add': true, 'edit': true, 'delete': false},
  ///     'chat': {'manage': true, 'delete_message': true},
  ///   },
  ///   changedBy: 'root-789',
  /// );
  /// ```
  Future<bool> updateAdminPermissions({
    required String adminId,
    required Map<String, dynamic> permissions,
    required String changedBy,
  }) async {
    try {
      final response = await _apiService.patch(
        '$_adminEndpoint/admins/$adminId/permissions',
        data: {
          'permissions': permissions,
          'changed_by': changedBy,
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Yönetici izinleri değiştirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yöneticiyi sil (Root işlemi)
  /// 
  /// [adminId]: Silinecek yönetici ID
  /// [deletedBy]: İşlemi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.removeAdmin(
  ///   adminId: 'admin-456',
  ///   deletedBy: 'root-789',
  /// );
  /// ```
  Future<bool> removeAdmin({
    required String adminId,
    required String deletedBy,
  }) async {
    try {
      final response = await _apiService.post(
        '$_adminEndpoint/admins/$adminId/remove',
        data: {'deleted_by': deletedBy},
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Yönetici silme hatası: ${e.message}');
      rethrow;
    }
  }

  // ============ SİSTEM AYARLARI ============

  /// Bakım modunu aç/kapat (Root işlemi)
  /// 
  /// [enabled]: Bakım modu açılsın mı?
  /// [message]: Bakım mesajı
  /// [rootId]: Root yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.setMaintenanceMode(
  ///   enabled: true,
  ///   message: 'Sistem bakımda, lütfen daha sonra tekrar deneyin.',
  ///   rootId: 'root-789',
  /// );
  /// ```
  Future<bool> setMaintenanceMode({
    required bool enabled,
    String? message,
    required String rootId,
  }) async {
    try {
      final response = await _apiService.patch(
        '$_adminEndpoint/system/maintenance',
        data: {
          'maintenance_mode': enabled,
          'maintenance_message': message,
          'changed_by': rootId,
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Bakım modu ayarlama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sistem istatistiklerini getir
  /// 
  /// Örnek:
  /// ```dart
  /// final stats = await adminRepository.getSystemStats();
  /// ```
  Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      final response = await _apiService.get(
        '$_adminEndpoint/system/stats',
      );
      return response['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      print('Sistem istatistikleri getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Uygulama yapılandırmasını getir
  /// 
  /// Örnek:
  /// ```dart
  /// final config = await adminRepository.getAppConfig();
  /// ```
  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final response = await _apiService.get(
        '$_adminEndpoint/system/config',
      );
      return response['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      print('Uygulama yapılandırması getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Uygulama yapılandırmasını güncelle (Root işlemi)
  /// 
  /// [config]: Yapılandırma verileri
  /// [rootId]: Root yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await adminRepository.updateAppConfig(
  ///   config: {
  ///     'telegram_channel_url': 'https://t.me/newchannel',
  ///     'website_url': 'https://newsite.com',
  ///   },
  ///   rootId: 'root-789',
  /// );
  /// ```
  Future<bool> updateAppConfig({
    required Map<String, dynamic> config,
    required String rootId,
  }) async {
    try {
      final response = await _apiService.patch(
        '$_adminEndpoint/system/config',
        data: {
          'config': config,
          'updated_by': rootId,
        },
      );
      return response['success'] == true;
    } on DioException catch (e) {
      print('Uygulama yapılandırması güncelleme hatası: ${e.message}');
      rethrow;
    }
  }
}
