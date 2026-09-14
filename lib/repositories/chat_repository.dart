import 'package:dio/dio.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

/// Sohbet Repository
/// 
/// Sohbet sistemiyle ilgili tüm veri işlemlerini yönetir.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Özellikler:
/// - Mesaj gönderme/silme
/// - Mesajları getirme (pagination)
/// - Sohbet ayarlarını yönetme (yönetici)
/// - Kullanıcı kısıtlamaları (susturma/engelleme)
/// - İtiraz yönetimi

class ChatRepository {
  final ApiService _apiService = ApiService();
  static const String _messagesEndpoint = '/chat';
  static const String _settingsEndpoint = '/chat-settings';
  static const String _restrictionsEndpoint = '/chat-user-restrictions';

  /// Sohbet mesajlarını getir (pagination ile)
  /// 
  /// [limit]: Kaç mesaj getirileceği (default: 50)
  /// [offset]: Kaç mesaj atlanacağı
  /// 
  /// Returns: Mesajlar listesi (eski mesajlar önce)
  /// 
  /// Örnek:
  /// ```dart
  /// final messages = await chatRepository.getMessages(limit: 100);
  /// ```
  Future<List<ChatMessage>> getMessages({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        _messagesEndpoint,
        queryParameters: {
          'is_deleted': false,
          'limit': limit,
          'offset': offset,
          'order': 'created_at.asc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Sohbet mesajları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Son mesajlardan itibaren getir (en yeni mesajlar önce)
  /// 
  /// [limit]: Kaç mesaj getirileceği
  /// 
  /// Returns: En yeni mesajlardan başlayan liste
  /// 
  /// Örnek:
  /// ```dart
  /// final latestMessages = await chatRepository.getLatestMessages(limit: 30);
  /// ```
  Future<List<ChatMessage>> getLatestMessages({int limit = 30}) async {
    try {
      final response = await _apiService.get(
        _messagesEndpoint,
        queryParameters: {
          'is_deleted': false,
          'limit': limit,
          'order': 'created_at.desc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      final messages = data
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Ters sıra çünkü API'den desc aldık, UI'da asc olsun
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return messages;
    } on DioException catch (e) {
      print('Son sohbet mesajları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Mesaj gönder
  /// 
  /// [userId]: Gönderen kullanıcı ID
  /// [message]: Mesaj metni
  /// 
  /// Returns: Gönderim başarı durumu
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.sendMessage(
  ///   userId: 'user-123',
  ///   message: 'Merhaba herkese!',
  /// );
  /// ```
  Future<bool> sendMessage({
    required String userId,
    required String message,
  }) async {
    try {
      await _apiService.post(
        _messagesEndpoint,
        data: {
          'user_id': userId,
          'message': message,
          'is_deleted': false,
        },
      );
      return true;
    } on DioException catch (e) {
      print('Mesaj gönderme hatası: ${e.message}');
      return false;
    }
  }

  /// Mesaj sil (Yönetici işlemi)
  /// 
  /// [messageId]: Silinecek mesaj ID
  /// [deletedBy]: Silme işlemini yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.deleteMessage(
  ///   messageId: 1,
  ///   deletedBy: 'admin-123',
  /// );
  /// ```
  Future<bool> deleteMessage({
    required int messageId,
    required String deletedBy,
  }) async {
    try {
      await _apiService.patch(
        '$_messagesEndpoint?id=eq.$messageId',
        data: {
          'is_deleted': true,
          'deleted_by': deletedBy,
          'deleted_at': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } on DioException catch (e) {
      print('Mesaj silme hatası: ${e.message}');
      return false;
    }
  }

  /// Sohbet ayarlarını getir
  /// 
  /// Returns: Sohbet ayarları
  /// 
  /// Örnek:
  /// ```dart
  /// final settings = await chatRepository.getSettings();
  /// ```
  Future<ChatSettings?> getSettings() async {
    try {
      final response = await _apiService.get(_settingsEndpoint);

      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return null;

      return ChatSettings.fromJson(data[0] as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Sohbet ayarları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sohbet ayarlarını güncelle (Yönetici işlemi)
  /// 
  /// [updates]: Güncellenecek alanlar
  /// - isOpen: Sohbet açık mı?
  /// - isSlowMode: Yavaş mod aktif mi?
  /// - slowModeInterval: Yavaş mod aralığı (1m, 2m, 5m, 10m, 60m)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.updateSettings({
  ///   'is_slow_mode': true,
  ///   'slow_mode_interval': '1m',
  /// });
  /// ```
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _apiService.patch(
        _settingsEndpoint,
        data: updates,
      );
    } on DioException catch (e) {
      print('Sohbet ayarları güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sohbeti temizle (Yönetici işlemi - tüm mesajları sil)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.clearChat();
  /// ```
  Future<bool> clearChat() async {
    try {
      await _apiService.post(
        '$_messagesEndpoint/clear',
        data: {},
      );
      return true;
    } on DioException catch (e) {
      print('Sohbet temizleme hatası: ${e.message}');
      return false;
    }
  }

  /// Kullanıcıyı sohbette sustur (Yönetici işlemi)
  /// 
  /// [userId]: Susturulacak kullanıcı ID
  /// [reason]: Sebep (opsiyonel)
  /// [duration]: Süre (opsiyonel, null = kalıcı)
  /// [restrictedBy]: Kısıtlamayı yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.muteUser(
  ///   userId: 'user-123',
  ///   reason: 'Spam mesaj',
  ///   duration: Duration(hours: 1),
  ///   restrictedBy: 'admin-123',
  /// );
  /// ```
  Future<bool> muteUser({
    required String userId,
    String? reason,
    Duration? duration,
    required String restrictedBy,
  }) async {
    try {
      await _apiService.post(
        _restrictionsEndpoint,
        data: {
          'user_id': userId,
          'restriction_type': 'muted',
          'reason': reason,
          'expires_at': duration != null
              ? DateTime.now().add(duration).toIso8601String()
              : null,
          'restricted_by': restrictedBy,
        },
      );
      return true;
    } on DioException catch (e) {
      print('Kullanıcı susturma hatası: ${e.message}');
      return false;
    }
  }

  /// Kullanıcıyı sohbetten engelle (Yönetici işlemi)
  /// 
  /// [userId]: Engellenecek kullanıcı ID
  /// [reason]: Sebep (opsiyonel)
  /// [duration]: Süre (opsiyonel, null = kalıcı)
  /// [restrictedBy]: Engellemeyi yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.blockUser(
  ///   userId: 'user-123',
  ///   reason: 'Hakaret',
  ///   restrictedBy: 'admin-123',
  /// );
  /// ```
  Future<bool> blockUser({
    required String userId,
    String? reason,
    Duration? duration,
    required String restrictedBy,
  }) async {
    try {
      await _apiService.post(
        _restrictionsEndpoint,
        data: {
          'user_id': userId,
          'restriction_type': 'blocked',
          'reason': reason,
          'expires_at': duration != null
              ? DateTime.now().add(duration).toIso8601String()
              : null,
          'restricted_by': restrictedBy,
        },
      );
      return true;
    } on DioException catch (e) {
      print('Kullanıcı engelleme hatası: ${e.message}');
      return false;
    }
  }

  /// Kullanıcının kısıtlamasını kaldır (Yönetici işlemi)
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.removeRestriction(restrictionId: 1);
  /// ```
  Future<bool> removeRestriction({required int restrictionId}) async {
    try {
      await _apiService.delete(
        '$_restrictionsEndpoint?id=eq.$restrictionId',
      );
      return true;
    } on DioException catch (e) {
      print('Kısıtlama kaldırma hatası: ${e.message}');
      return false;
    }
  }

  /// Kullanıcı kısıtlamasını getir
  /// 
  /// [userId]: Kullanıcı ID
  /// 
  /// Returns: Aktif kısıtlamalar
  /// 
  /// Örnek:
  /// ```dart
  /// final restrictions = await chatRepository.getUserRestrictions('user-123');
  /// ```
  Future<List<ChatUserRestriction>> getUserRestrictions(String userId) async {
    try {
      final response = await _apiService.get(
        _restrictionsEndpoint,
        queryParameters: {
          'user_id': 'eq.$userId',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => ChatUserRestriction.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Kullanıcı kısıtlaması getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// İtiraz gönder (Engellenen kullanıcı)
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// [appealMessage]: İtiraz mesajı
  /// 
  /// Örnek:
  /// ```dart
  /// await chatRepository.submitAppeal(
  ///   restrictionId: 1,
  ///   appealMessage: 'Yanlışlıkla yapmış olabilirim, özür dilerim.',
  /// );
  /// ```
  Future<bool> submitAppeal({
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
      return true;
    } on DioException catch (e) {
      print('İtiraz gönderme hatası: ${e.message}');
      return false;
    }
  }
}
