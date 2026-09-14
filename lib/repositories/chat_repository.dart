import 'package:dio/dio.dart';
import '../services/api_service.dart';

/// Sohbet Repository
/// 
/// Sohbet sistemiyle ilgili tüm veri işlemlerini yönetir.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Bu repository:
/// - Sohbet mesajlarını yönetir
/// - Sohbet ayarlarını kontrol eder
/// - Kullanıcı kısıtlamalarını yönetir
/// - Raporları işler

class ChatRepository {
  final ApiService _apiService = ApiService();
  static const String _messagesEndpoint = '/chat';
  static const String _settingsEndpoint = '/chat-settings';
  static const String _restrictionsEndpoint = '/chat-user-restrictions';

  /// Sohbet mesajlarını getir
  /// 
  /// [limit]: Kaç mesaj getirileceği
  /// [offset]: Kaç mesaj atlanacağı (pagination için)
  /// 
  /// Returns: Mesaj listesi (en yeniden en eskiye)
  /// 
  /// Örnek:
  /// ```dart
  /// final messages = await chatRepository.getMessages(limit: 50);
  /// ```
  Future<List<Map<String, dynamic>>> getMessages({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        _messagesEndpoint,
        queryParameters: {
          'order': 'created_at.desc',
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Sohbet mesajları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Mesaj gönder
  /// 
  /// [userId]: Gönderen kullanıcı ID
  /// [message]: Mesaj metni
  /// 
  /// Returns: Gönderilen mesaj
  /// 
  /// Örnek:
  /// ```dart
  /// final sent = await chatRepository.sendMessage(
  ///   userId: 'user-id',
  ///   message: 'Merhaba!',
  /// );
  /// ```
  Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String message,
  }) async {
    try {
      final response = await _apiService.post(
        _messagesEndpoint,
        data: {
          'user_id': userId,
          'message': message,
        },
      );

      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Mesaj gönderme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Mesajı sil (Yönetici işlemi)
  /// 
  /// [messageId]: Silinecek mesaj ID
  /// [adminId]: Admin ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.deleteMessage(messageId: 1, adminId: 'admin-id');
  /// ```
  Future<void> deleteMessage({
    required int messageId,
    required String adminId,
  }) async {
    try {
      await _apiService.patch(
        '$_messagesEndpoint?id=eq.$messageId',
        data: {
          'is_deleted': true,
          'deleted_by': adminId,
          'deleted_at': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      print('Mesaj silme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sohbet ayarlarını getir
  /// 
  /// Returns: Sohbet ayarları
  /// 
  /// Örnek:
  /// ```dart
  /// final settings = await chatRepository.getChatSettings();
  /// ```
  Future<Map<String, dynamic>?> getChatSettings() async {
    try {
      final response = await _apiService.get(_settingsEndpoint);
      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return null;

      return data[0] as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Sohbet ayarları getirme hatası: ${e.message}');
      return null;
    }
  }

  /// Sohbeti aç/kapat (Yönetici işlemi)
  /// 
  /// [isOpen]: Sohbet açık mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.toggleChat(isOpen: false);
  /// ```
  Future<void> toggleChat({required bool isOpen}) async {
    try {
      await _apiService.patch(
        _settingsEndpoint,
        data: {'is_open': isOpen},
      );
    } on DioException catch (e) {
      print('Sohbet aç/kapat hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yavaş modu etkinleştir/devre dışı bırak (Yönetici işlemi)
  /// 
  /// [isSlowMode]: Yavaş mod aktif mi?
  /// [interval]: Aralık (1m, 2m, 5m, 10m, 60m)
  /// [exemptTiers]: Muaf kullanıcı seviyeleri
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.toggleSlowMode(
  ///   isSlowMode: true,
  ///   interval: '5m',
  ///   exemptTiers: ['vip', 'admin'],
  /// );
  /// ```
  Future<void> toggleSlowMode({
    required bool isSlowMode,
    String? interval,
    List<String>? exemptTiers,
  }) async {
    try {
      await _apiService.patch(
        _settingsEndpoint,
        data: {
          'is_slow_mode': isSlowMode,
          'slow_mode_interval': interval,
          'exempt_user_tiers': exemptTiers,
        },
      );
    } on DioException catch (e) {
      print('Yavaş mod değişimi hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sohbeti temizle (Yönetici işlemi)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.clearChat();
  /// ```
  Future<void> clearChat() async {
    try {
      // Tüm mesajları sil
      final messages = await getMessages(limit: 10000);
      for (var message in messages) {
        await deleteMessage(
          messageId: message['id'],
          adminId: 'system',
        );
      }
    } on DioException catch (e) {
      print('Sohbet temizleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı susttur (Yönetici işlemi)
  /// 
  /// [userId]: Susturulacak kullanıcı ID
  /// [adminId]: İşlemi yapan admin ID
  /// [expiresAt]: Susturma ne kadar sürecek (NULL = kalıcı)
  /// [reason]: Sebep
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.muteUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  ///   expiresAt: DateTime.now().add(Duration(hours: 1)),
  ///   reason: 'Spam',
  /// );
  /// ```
  Future<void> muteUser({
    required String userId,
    required String adminId,
    DateTime? expiresAt,
    String? reason,
  }) async {
    try {
      await _apiService.post(
        _restrictionsEndpoint,
        data: {
          'user_id': userId,
          'restriction_type': 'muted',
          'restricted_by': adminId,
          'expires_at': expiresAt?.toIso8601String(),
          'reason': reason,
        },
      );
    } on DioException catch (e) {
      print('Kullanıcı susturma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcıyı engelle (Yönetici işlemi)
  /// 
  /// [userId]: Engellenecek kullanıcı ID
  /// [adminId]: İşlemi yapan admin ID
  /// [expiresAt]: Engelleme ne kadar sürecek (NULL = kalıcı)
  /// [reason]: Sebep
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.blockUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  ///   expiresAt: DateTime.now().add(Duration(days: 7)),
  ///   reason: 'Küfür',
  /// );
  /// ```
  Future<void> blockUser({
    required String userId,
    required String adminId,
    DateTime? expiresAt,
    String? reason,
  }) async {
    try {
      await _apiService.post(
        _restrictionsEndpoint,
        data: {
          'user_id': userId,
          'restriction_type': 'blocked',
          'restricted_by': adminId,
          'expires_at': expiresAt?.toIso8601String(),
          'reason': reason,
        },
      );
    } on DioException catch (e) {
      print('Kullanıcı engelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kısıtlamayı kaldır (Yönetici işlemi)
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.removeRestriction(restrictionId: 1);
  /// ```
  Future<void> removeRestriction({required int restrictionId}) async {
    try {
      await _apiService.delete(
        '$_restrictionsEndpoint?id=eq.$restrictionId',
      );
    } on DioException catch (e) {
      print('Kısıtlama kaldırma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kullanıcının kısıtlamalarını getir
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Returns: Aktif kısıtlamalar
  /// 
  /// Örnek:
  /// ```dart
  /// final restrictions = await chatRepository.getUserRestrictions('user-id');
  /// ```
  Future<List<Map<String, dynamic>>> getUserRestrictions(
    String userId,
  ) async {
    try {
      final response = await _apiService.get(
        _restrictionsEndpoint,
        queryParameters: {
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Kullanıcı kısıtlamaları getirme hatası: ${e.message}');
      return [];
    }
  }

  /// İtiraz gönder
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// [appealMessage]: İtiraz mesajı
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.submitAppeal(
  ///   restrictionId: 1,
  ///   appealMessage: 'Yanlışlıkla yapıldı',
  /// );
  /// ```
  Future<void> submitAppeal({
    required int restrictionId,
    required String appealMessage,
  }) async {
    try {
      await _apiService.patch(
        '$_restrictionsEndpoint?id=eq.$restrictionId',
        data: {
          'is_appealed': true,
          'appeal_message': appealMessage,
        },
      );
    } on DioException catch (e) {
      print('İtiraz gönderme hatası: ${e.message}');
      rethrow;
    }
  }
}
