import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';

/// Sohbet Provider
/// 
/// Sohbet sistemiyle ilgili tüm state yönetimini yapar.
/// Mesajları yükle, gönder, yönetici işlemleri vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikler:
/// - Mesaj listeleme (pagination)
/// - Mesaj gönderme/silme
/// - Yönetici işlemleri (susturma, engelleme)
/// - Sohbet ayarları
/// - Realtime mesaj güncellemeleri (gelecekte Supabase Realtime ile)

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  /// Sohbet mesajları
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  /// Sohbet ayarları
  ChatSettings? _chatSettings;
  ChatSettings? get chatSettings => _chatSettings;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  /// Sohbet açık mı?
  bool _isChatOpen = true;
  bool get isChatOpen => _isChatOpen;

  /// Yavaş mod aktif mi?
  bool _isSlowModeActive = false;
  bool get isSlowModeActive => _isSlowModeActive;

  /// Kullanıcı susturulmuş mu?
  bool _isUserMuted = false;
  bool get isUserMuted => _isUserMuted;

  /// Kullanıcı engellenmis mi?
  bool _isUserBlocked = false;
  bool get isUserBlocked => _isUserBlocked;

  /// Mesaj gönderme zamanı limiti (yavaş mod için)
  Duration _messageDelay = const Duration(seconds: 0);
  Duration get messageDelay => _messageDelay;

  /// Sohbeti başlat (ilk veriler yükleme)
  /// 
  /// [userId]: Kullanıcı ID (kısıtlamalar kontrol için)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.initializeChat(userId: 'user-123');
  /// ```
  Future<void> initializeChat({required String userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Sohbet ayarlarını yükle
      _chatSettings = await _chatRepository.getSettings();
      _isChatOpen = _chatSettings?.isOpen ?? true;
      _isSlowModeActive = _chatSettings?.isSlowMode ?? false;

      // Yavaş mod aralığını ayarla
      if (_isSlowModeActive) {
        _messageDelay = _parseSlowModeInterval(
          _chatSettings?.slowModeInterval ?? '1m',
        );
      }

      // Kullanıcı kısıtlamalarını kontrol et
      final restrictions = await _chatRepository.getUserRestrictions(userId);
      for (var restriction in restrictions) {
        if (restriction.isActive) {
          if (restriction.restrictionType == 'muted') {
            _isUserMuted = true;
          } else if (restriction.restrictionType == 'blocked') {
            _isUserBlocked = true;
          }
        }
      }

      // Mesajları yükle
      await loadMessages();
      _error = null;
    } catch (e) {
      _error = 'Sohbet başlatma hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sohbet mesajlarını yükle
  /// 
  /// [limit]: Kaç mesaj getirilecek
  /// [offset]: Pagination offset
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.loadMessages(limit: 100);
  /// ```
  Future<void> loadMessages({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _chatRepository.getMessages(
        limit: limit,
        offset: offset,
      );
      _messages = messages;
      _error = null;
    } catch (e) {
      _error = 'Mesajlar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Son mesajları yükle (en yeni mesajlar ilk)
  /// 
  /// [limit]: Kaç mesaj getirilecek
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.loadLatestMessages(limit: 30);
  /// ```
  Future<void> loadLatestMessages({int limit = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _chatRepository.getLatestMessages(limit: limit);
      _messages = messages;
      _error = null;
    } catch (e) {
      _error = 'Son mesajlar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mesaj gönder
  /// 
  /// [userId]: Gönderen kullanıcı ID
  /// [message]: Mesaj metni
  /// 
  /// Returns: Gönderim başarılı mı?
  /// 
  /// Hata durumları:
  /// - Sohbet kapalı
  /// - Kullanıcı susturulmuş
  /// - Kullanıcı engellenmis
  /// - Yavaş mod geciklemesi
  /// 
  /// Örnek:
  /// ```dart
  /// final success = await chatProvider.sendMessage(
  ///   userId: 'user-123',
  ///   message: 'Merhaba herkese!',
  /// );
  /// ```
  Future<bool> sendMessage({
    required String userId,
    required String message,
  }) async {
    // Sohbet açık mı kontrol et
    if (!_isChatOpen) {
      _error = 'Sohbet şu anda kapalı';
      notifyListeners();
      return false;
    }

    // Kullanıcı susturulmuş mı kontrol et
    if (_isUserMuted) {
      _error = 'Sohbette mesaj gönderme hakkınız olmadığı için susturuldunuz';
      notifyListeners();
      return false;
    }

    // Kullanıcı engellenmis mi kontrol et
    if (_isUserBlocked) {
      _error = 'Sohbette engellenmişsiniz';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _chatRepository.sendMessage(
        userId: userId,
        message: message,
      );

      if (success) {
        // Mesajı listeye ekle
        final newMessage = ChatMessage(
          id: _messages.length + 1,
          userId: userId,
          message: message,
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _messages.add(newMessage);
        _error = null;
      }
      return success;
    } catch (e) {
      _error = 'Mesaj gönderme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mesaj sil (Yönetici işlemi)
  /// 
  /// [messageId]: Silinecek mesaj ID
  /// [deletedBy]: Silme işlemini yapan yönetici ID
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.deleteMessage(
  ///   messageId: 1,
  ///   deletedBy: 'admin-123',
  /// );
  /// ```
  Future<bool> deleteMessage({
    required int messageId,
    required String deletedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _chatRepository.deleteMessage(
        messageId: messageId,
        deletedBy: deletedBy,
      );

      if (success) {
        // Mesajı listeden kaldır veya silinmiş olarak işaretle
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isDeleted: true,
          ) as ChatMessage;
        }
      }
      return success;
    } catch (e) {
      _error = 'Mesaj silme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
  /// await chatProvider.muteUser(
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
    _isLoading = true;
    notifyListeners();

    try {
      return await _chatRepository.muteUser(
        userId: userId,
        reason: reason,
        duration: duration,
        restrictedBy: restrictedBy,
      );
    } catch (e) {
      _error = 'Kullanıcı susturma hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
  /// await chatProvider.blockUser(
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
    _isLoading = true;
    notifyListeners();

    try {
      return await _chatRepository.blockUser(
        userId: userId,
        reason: reason,
        duration: duration,
        restrictedBy: restrictedBy,
      );
    } catch (e) {
      _error = 'Kullanıcı engelleme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sohbeti temizle - tüm mesajları sil (Yönetici işlemi)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.clearChat();
  /// ```
  Future<bool> clearChat() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _chatRepository.clearChat();
      if (success) {
        _messages = [];
      }
      return success;
    } catch (e) {
      _error = 'Sohbet temizleme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sohbet ayarlarını güncelle (Yönetici işlemi)
  /// 
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.updateSettings({
  ///   'is_slow_mode': true,
  ///   'slow_mode_interval': '1m',
  /// });
  /// ```
  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _chatRepository.updateSettings(updates);

      // Local state'i güncelle
      if (updates.containsKey('is_open')) {
        _isChatOpen = updates['is_open'] as bool;
      }
      if (updates.containsKey('is_slow_mode')) {
        _isSlowModeActive = updates['is_slow_mode'] as bool;
      }
      if (updates.containsKey('slow_mode_interval')) {
        _messageDelay = _parseSlowModeInterval(
          updates['slow_mode_interval'] as String,
        );
      }
      return true;
    } catch (e) {
      _error = 'Sohbet ayarları güncelleme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// İtiraz gönder (Engellenen kullanıcı)
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// [appealMessage]: İtiraz mesajı
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.submitAppeal(
  ///   restrictionId: 1,
  ///   appealMessage: 'Yanlışlıkla yapmış olabilirim',
  /// );
  /// ```
  Future<bool> submitAppeal({
    required int restrictionId,
    required String appealMessage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _chatRepository.submitAppeal(
        restrictionId: restrictionId,
        appealMessage: appealMessage,
      );
    } catch (e) {
      _error = 'İtiraz gönderme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yavaş mod aralığını parse et (string'ten Duration'a)
  /// 
  /// [interval]: Aralık string'i (1m, 2m, 5m, 10m, 60m)
  Duration _parseSlowModeInterval(String interval) {
    final parts = interval.split('');
    if (parts.length < 2) return const Duration(minutes: 1);

    final number = int.tryParse(parts.sublist(0, parts.length - 1).join(''));
    final unit = parts.last;

    if (number == null) return const Duration(minutes: 1);

    switch (unit.toLowerCase()) {
      case 'm':
        return Duration(minutes: number);
      case 's':
        return Duration(seconds: number);
      case 'h':
        return Duration(hours: number);
      default:
        return const Duration(minutes: 1);
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Tüm veriyi sıfırla
  void reset() {
    _messages = [];
    _chatSettings = null;
    _currentPage = 0;
    _isChatOpen = true;
    _isSlowModeActive = false;
    _isUserMuted = false;
    _isUserBlocked = false;
    _messageDelay = const Duration(seconds: 0);
    _error = null;
    notifyListeners();
  }
}
