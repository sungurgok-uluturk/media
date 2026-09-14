import 'package:flutter/material.dart';
import '../models/radio_channel_model.dart';
import '../repositories/radio_repository.dart';

/// Radyo Kanalları Provider
/// 
/// Radyo kanallarıyla ilgili tüm state yönetimini yapar.
/// Kanalları yükle, seçili kanalı tut, oynatıcı kontrolü vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikler:
/// - Kanal listeleme (search desteği)
/// - Seçili kanal yönetimi
/// - Oynatıcı kontrolü (play, pause, next, previous)
/// - Kategori filtreleme
/// - Pagination desteği

class RadioProvider extends ChangeNotifier {
  final RadioRepository _radioRepository = RadioRepository();

  /// Tüm radyo kanalları
  List<RadioChannel> _channels = [];
  List<RadioChannel> get channels => _channels;

  /// Seçili kanal
  RadioChannel? _selectedChannel;
  RadioChannel? get selectedChannel => _selectedChannel;

  /// Oynatma durumu
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  /// Seçili kategori
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  /// Arama sorgusu
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Tüm kategoriler
  List<String> _categories = [];
  List<String> get categories => _categories;

  /// Tüm kanalları yükle
  /// 
  /// [forceRefresh]: Öncekten yükleme mi, yoksa API'den yükleme mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.loadChannels();
  /// ```
  Future<void> loadChannels({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final channels = await _radioRepository.getAllChannels(
        limit: 10,
        offset: _currentPage * 10,
      );
      _channels = channels;
      _error = null;
    } catch (e) {
      _error = 'Kanallar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kategoriye göre kanalları yükle
  /// 
  /// [category]: Kategori adı (Müzik, Haber, Spor vb)
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.loadChannelsByCategory('Müzik');
  /// ```
  Future<void> loadChannelsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    _selectedCategory = category;
    notifyListeners();

    try {
      final channels = await _radioRepository.getChannelsByCategory(category);
      _channels = channels;
      _error = null;
    } catch (e) {
      _error = 'Kategoriye göre kanallar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Radyo kanallarında arama yap
  /// 
  /// [query]: Aranacak kelime
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.searchChannels('TRT');
  /// ```
  Future<void> searchChannels(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await loadChannels();
      } else {
        final results = await _radioRepository.searchChannels(query);
        _channels = results;
        _error = null;
      }
    } catch (e) {
      _error = 'Arama sırasında hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kanal seç ve oynatmaya başla
  /// 
  /// [channel]: Seçilecek kanal
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.selectChannel(channel);
  /// ```
  Future<void> selectChannel(RadioChannel channel) async {
    _selectedChannel = channel;
    _isPlaying = true;
    _error = null;
    notifyListeners();

    try {
      // Gerçek uygulamada burada audio player başlatılır
      // AudioPlayer().play(_selectedChannel!.streamUrl);
    } catch (e) {
      _error = 'Kanal seçme hatası: $e';
      _isPlaying = false;
    } finally {
      notifyListeners();
    }
  }

  /// Oynatmayı duraklat
  /// 
  /// Örnek:
  /// ```dart
  /// radioProvider.pause();
  /// ```
  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  /// Oynatmaya devam et
  /// 
  /// Örnek:
  /// ```dart
  /// radioProvider.resume();
  /// ```
  void resume() {
    _isPlaying = true;
    notifyListeners();
  }

  /// Önceki kanala geç
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.previousChannel();
  /// ```
  Future<void> previousChannel() async {
    if (_selectedChannel == null || _channels.isEmpty) return;

    final currentIndex = _channels.indexOf(_selectedChannel!);
    if (currentIndex > 0) {
      await selectChannel(_channels[currentIndex - 1]);
    }
  }

  /// Sonraki kanala geç
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.nextChannel();
  /// ```
  Future<void> nextChannel() async {
    if (_selectedChannel == null || _channels.isEmpty) return;

    final currentIndex = _channels.indexOf(_selectedChannel!);
    if (currentIndex < _channels.length - 1) {
      await selectChannel(_channels[currentIndex + 1]);
    }
  }

  /// Kanal rapor et
  /// 
  /// [channelId]: Rapor edilen kanal ID
  /// [description]: Sorun açıklaması
  /// [userId]: Raporlayan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.reportChannel(
  ///   channelId: 1,
  ///   description: 'Yayın kesildi',
  ///   userId: currentUser.id,
  /// );
  /// ```
  Future<bool> reportChannel({
    required int channelId,
    required String description,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _radioRepository.reportChannel(
        channelId: channelId,
        description: description,
        userId: userId,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = 'Rapor etme hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Daha fazla kanal yükle (pagination)
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.loadMoreChannels();
  /// ```
  Future<void> loadMoreChannels() async {
    _currentPage++;
    _isLoading = true;
    notifyListeners();

    try {
      final moreChannels = await _radioRepository.getAllChannels(
        limit: 10,
        offset: _currentPage * 10,
      );
      _channels.addAll(moreChannels);
      _error = null;
    } catch (e) {
      _error = 'Daha fazla kanal yüklenirken hata: $e';
      _currentPage--; // Hata durumunda sayfayı geri al
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kategorileri yükle
  /// 
  /// Örnek:
  /// ```dart
  /// await radioProvider.loadCategories();
  /// ```
  Future<void> loadCategories() async {
    try {
      _categories = await _radioRepository.getCategories();
      notifyListeners();
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Tüm veriyi sıfırla
  void reset() {
    _channels = [];
    _selectedChannel = null;
    _isPlaying = false;
    _currentPage = 0;
    _selectedCategory = null;
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }
}
