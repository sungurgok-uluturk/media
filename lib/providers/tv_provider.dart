import 'package:flutter/material.dart';
import '../models/tv_channel_model.dart';
import '../repositories/tv_repository.dart';

/// TV Kanalları Provider
/// 
/// TV kanallarıyla ilgili tüm state yönetimini yapar.
/// Kanalları yükle, seçili kanalı tut, URL'leri yönet vb.
/// 
/// State Management: Provider kullanılır

class TvProvider extends ChangeNotifier {
  final TvRepository _tvRepository = TvRepository();

  /// Tüm TV kanalları
  List<TvChannel> _channels = [];
  List<TvChannel> get channels => _channels;

  /// Seçili kanal
  TvChannel? _selectedChannel;
  TvChannel? get selectedChannel => _selectedChannel;

  /// Seçili kanalın URL'leri
  List<TvChannelUrl> _selectedChannelUrls = [];
  List<TvChannelUrl> get selectedChannelUrls => _selectedChannelUrls;

  /// Seçili kalite
  String _selectedQuality = 'auto';
  String get selectedQuality => _selectedQuality;

  /// Seçili kanal URL'si
  String? _selectedStreamUrl;
  String? get selectedStreamUrl => _selectedStreamUrl;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  /// Tüm kanalları yükle
  /// 
  /// [forceRefresh]: Önbellekten yükle mi, yoksa API'den yükle mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await tvProvider.loadChannels();
  /// ```
  Future<void> loadChannels({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final channels = await _tvRepository.getAllChannels(
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
  /// [category]: Kategori adı (örn: "Ulusal", "Spor")
  /// 
  /// Örnek:
  /// ```dart
  /// await tvProvider.loadChannelsByCategory('Spor');
  /// ```
  Future<void> loadChannelsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final channels = await _tvRepository.getChannelsByCategory(category);
      _channels = channels;
      _error = null;
    } catch (e) {
      _error = 'Kategoriye göre kanallar yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kanal seç ve URL'lerini yükle
  /// 
  /// [channel]: Seçilecek kanal
  /// 
  /// Örnek:
  /// ```dart
  /// await tvProvider.selectChannel(channel);
  /// ```
  Future<void> selectChannel(TvChannel channel) async {
    _selectedChannel = channel;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Kanal URL'lerini yükle
      final urls = await _tvRepository.getChannelUrls(channel.id);
      _selectedChannelUrls = urls;

      // Auto kalitesinde başlat
      _selectedQuality = 'auto';
      final autoUrl = urls.firstWhere(
        (url) => url.quality == 'auto',
        orElse: () => urls.first,
      );
      _selectedStreamUrl = autoUrl.streamUrl;
      _error = null;
    } catch (e) {
      _error = 'Kanal seçme hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yayın kalitesini değiştir
  /// 
  /// [quality]: Yeni kalite (360p, 720p, 1080p vb)
  /// 
  /// Örnek:
  /// ```dart
  /// await tvProvider.changeQuality('1080p');
  /// ```
  Future<void> changeQuality(String quality) async {
    _selectedQuality = quality;
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _tvRepository.getChannelUrlByQuality(
        _selectedChannel!.id,
        quality,
      );
      _selectedStreamUrl = url?.streamUrl;
      _error = null;
    } catch (e) {
      _error = 'Kalite değiştirme hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Önceki kanala geç
  /// 
  /// Örnek:
  /// ```dart
  /// await tvProvider.previousChannel();
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
  /// await tvProvider.nextChannel();
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
  /// await tvProvider.reportChannel(
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
      await _tvRepository.reportChannel(
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
  /// await tvProvider.loadMoreChannels();
  /// ```
  Future<void> loadMoreChannels() async {
    _currentPage++;
    _isLoading = true;
    notifyListeners();

    try {
      final moreChannels = await _tvRepository.getAllChannels(
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

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
