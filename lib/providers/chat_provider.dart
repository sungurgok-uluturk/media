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
/// Özellikleri:
/// - Mesaj listeleme ve gönderme
/// - Gerçek zamanlı mesaj alımı
/// - Yönetici işlemleri (susturma, engelleme)
/// - Sohbet ayarları

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  /// Tüm mesajlar
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  /// Sohbet ayarları
  Map<String, dynamic>? _chatSettings;
  Map<String, dynamic>? get chatSettings => _chatSettings;

  /// Sohbet açık mı?
  bool _isChatOpen = true;
  bool get isChatOpen => _isChatOpen;

  /// Yavaş mod aktif mi?
  bool _isSlowMode = false;
  bool get isSlowMode => _isSlowMode;

  /// Yavaş mod aralığı
  String? _slowModeInterval;
  String? get slowModeInterval => _slowModeInterval;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Mesaj gönderme durumu
  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  ChatProvider() {
    _initialize();
  }

  /// Provider'ı başlat
  Future<void> _initialize() async {
    await _loadChatSettings();
    await loadMessages();
  }

  /// Sohbet ayarlarını yükle
  Future<void> _loadChatSettings() async {
    try {
      final settings = await _chatRepository.getChatSettings();
      _chatSettings = settings;
      _isChatOpen = settings?['is_open'] ?? true;
      _isSlowMode = settings?['is_slow_mode'] ?? false;
      _slowModeInterval = settings?['slow_mode_interval'];
      notifyListeners();
    } catch (e) {
      print('Load chat settings error: $e');
    }
  }

  /// Mesajları yükle
  /// 
  /// [forceRefresh]: Önbellekten yükle mi, yoksa API'den yükle mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.loadMessages();
  /// ```
  Future<void> loadMessages({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    notifyListeners();

    try {
      final messages = await _chatRepository.getMessages(
        limit: 50,
        offset: 0,
      );
      _messages = messages;
      _error = null;
    } catch (e) {
      _error = 'Mesajlar yüklenirken hata: $e';
      print('Load messages error: $e');
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
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// final success = await chatProvider.sendMessage(
  ///   userId: 'user-id',
  ///   message: 'Merhaba!',
  /// );
  /// ```
  Future<bool> sendMessage({
    required String userId,
    required String message,
  }) async {
    if (message.isEmpty) return false;
    if (!_isChatOpen) {
      _error = 'Sohbet şu anda kapalı';
      notifyListeners();
      return false;
    }

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      final sentMessage = await _chatRepository.sendMessage(
        userId: userId,
        message: message,
      );

      // Mesajı listeye ekle (üste ekle, en yeni en başta)
      _messages.insert(0, sentMessage);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Mesaj gönderme hatası: $e';
      print('Send message error: $e');
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Daha fazla mesaj yükle (pagination)
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.loadMoreMessages();
  /// ```
  Future<void> loadMoreMessages() async {
    _currentPage++;
    _isLoading = true;
    notifyListeners();

    try {
      final moreMessages = await _chatRepository.getMessages(
        limit: 50,
        offset: _currentPage * 50,
      );
      _messages.addAll(moreMessages);
      _error = null;
    } catch (e) {
      _error = 'Daha fazla mesaj yüklenirken hata: $e';
      _currentPage--; // Hata durumunda sayfayı geri al
      print('Load more messages error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mesajı sil (Yönetici işlemi)
  /// 
  /// [messageId]: Silinecek mesaj ID
  /// [adminId]: Admin ID
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.deleteMessage(
  ///   messageId: 1,
  ///   adminId: 'admin-id',
  /// );
  /// ```
  Future<bool> deleteMessage({
    required int messageId,
    required String adminId,
  }) async {
    try {
      await _chatRepository.deleteMessage(
        messageId: messageId,
        adminId: adminId,
      );

      // Mesajı listeden kaldır
      _messages.removeWhere((msg) => msg['id'] == messageId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Mesaj silme hatası: $e';
      print('Delete message error: $e');
      return false;
    }
  }

  /// Sohbeti aç/kapat (Yönetici işlemi)
  /// 
  /// [isOpen]: Sohbet açık mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.toggleChat(isOpen: false);
  /// ```
  Future<bool> toggleChat({required bool isOpen}) async {
    try {
      await _chatRepository.toggleChat(isOpen: isOpen);
      _isChatOpen = isOpen;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Sohbet aç/kapat hatası: $e';
      print('Toggle chat error: $e');
      return false;
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
  /// await chatProvider.toggleSlowMode(
  ///   isSlowMode: true,
  ///   interval: '5m',
  ///   exemptTiers: ['vip', 'admin'],
  /// );
  /// ```
  Future<bool> toggleSlowMode({
    required bool isSlowMode,
    String? interval,
    List<String>? exemptTiers,
  }) async {
    try {
      await _chatRepository.toggleSlowMode(
        isSlowMode: isSlowMode,
        interval: interval,
        exemptTiers: exemptTiers,
      );
      _isSlowMode = isSlowMode;
      _slowModeInterval = interval;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Yavaş mod değişimi hatası: $e';
      print('Toggle slow mode error: $e');
      return false;
    }
  }

  /// Sohbeti temizle (Yönetici işlemi)
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.clearChat();
  /// ```
  Future<bool> clearChat() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _chatRepository.clearChat();
      _messages = [];
      _error = null;
      return true;
    } catch (e) {
      _error = 'Sohbet temizleme hatası: $e';
      print('Clear chat error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcıyı susttur (Yönetici işlemi)
  /// 
  /// [userId]: Susturulacak kullanıcı ID
  /// [adminId]: İşlemi yapan admin ID
  /// [expiresAt]: Susturma ne kadar sürecek (NULL = kalıcı)
  /// [reason]: Sebep
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.muteUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  ///   expiresAt: DateTime.now().add(Duration(hours: 1)),
  ///   reason: 'Spam',
  /// );
  /// ```
  Future<bool> muteUser({
    required String userId,
    required String adminId,
    DateTime? expiresAt,
    String? reason,
  }) async {
    try {
      await _chatRepository.muteUser(
        userId: userId,
        adminId: adminId,
        expiresAt: expiresAt,
        reason: reason,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kullanıcı susturma hatası: $e';
      print('Mute user error: $e');
      return false;
    }
  }

  /// Kullanıcıyı engelle (Yönetici işlemi)
  /// 
  /// [userId]: Engellenecek kullanıcı ID
  /// [adminId]: İşlemi yapan admin ID
  /// [expiresAt]: Engelleme ne kadar sürecek (NULL = kalıcı)
  /// [reason]: Sebep
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.blockUser(
  ///   userId: 'user-id',
  ///   adminId: 'admin-id',
  ///   expiresAt: DateTime.now().add(Duration(days: 7)),
  ///   reason: 'Küfür',
  /// );
  /// ```
  Future<bool> blockUser({
    required String userId,
    required String adminId,
    DateTime? expiresAt,
    String? reason,
  }) async {
    try {
      await _chatRepository.blockUser(
        userId: userId,
        adminId: adminId,
        expiresAt: expiresAt,
        reason: reason,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kullanıcı engelleme hatası: $e';
      print('Block user error: $e');
      return false;
    }
  }

  /// Kısıtlamayı kaldır (Yönetici işlemi)
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.removeRestriction(restrictionId: 1);
  /// ```
  Future<bool> removeRestriction({required int restrictionId}) async {
    try {
      await _chatRepository.removeRestriction(restrictionId: restrictionId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kısıtlama kaldırma hatası: $e';
      print('Remove restriction error: $e');
      return false;
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
  /// final restrictions = await chatProvider.getUserRestrictions('user-id');
  /// ```
  Future<List<Map<String, dynamic>>> getUserRestrictions(
    String userId,
  ) async {
    try {
      return await _chatRepository.getUserRestrictions(userId);
    } catch (e) {
      print('Get user restrictions error: $e');
      return [];
    }
  }

  /// İtiraz gönder
  /// 
  /// [restrictionId]: Kısıtlama ID
  /// [appealMessage]: İtiraz mesajı
  /// 
  /// Returns: İşlem başarılı mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await chatProvider.submitAppeal(
  ///   restrictionId: 1,
  ///   appealMessage: 'Yanlışlıkla yapıldı',
  /// );
  /// ```
  Future<bool> submitAppeal({
    required int restrictionId,
    required String appealMessage,
  }) async {
    try {
      await _chatRepository.submitAppeal(
        restrictionId: restrictionId,
        appealMessage: appealMessage,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'İtiraz gönderme hatası: $e';
      print('Submit appeal error: $e');
      return false;
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
