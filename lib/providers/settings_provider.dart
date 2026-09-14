import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Ayarlar Provider
/// 
/// Uygulama ayarlarını ve kullanıcı tercihlerini yönetir.
/// Tema, dil, oynatıcı ayarları, bildirimler vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Saklama:
/// - SharedPreferences: Uygulama ayarları
/// - SQLite: Komplex veriler (gelecekte)
/// - Supabase: Bulut senkronizasyonu (opsiyonel)

class SettingsProvider extends ChangeNotifier {
  // Tema Ayarları
  String _theme = 'light'; // light, dark, system
  String get theme => _theme;

  // Dil Ayarları
  String _language = 'tr'; // tr, en
  String get language => _language;

  // Bildirim Ayarları
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  // TV Player Ayarları
  bool _tvPlayerFullscreen = true; // Tam ekran mı başlasın?
  bool get tvPlayerFullscreen => _tvPlayerFullscreen;

  String _tvChannelListPosition = 'right'; // left, right, top, bottom
  String get tvChannelListPosition => _tvChannelListPosition;

  String _tvChannelListOpacity = 'transparent'; // transparent, opaque
  String get tvChannelListOpacity => _tvChannelListOpacity;

  // Radyo Player Ayarları
  bool _radioPlayerMinimize = true; // Minimize edilebilir mi?
  bool get radioPlayerMinimize => _radioPlayerMinimize;

  // Film Listeleme Ayarları
  String _movieViewMode = 'grid'; // list, grid
  String get movieViewMode => _movieViewMode;

  int _moviesPerPage = 10; // Sayfa başına film sayısı
  int get moviesPerPage => _moviesPerPage;

  // Ana Sekme Ayarı
  String _defaultTab = 'tv'; // tv, radio, movies, chat, settings
  String get defaultTab => _defaultTab;

  // Bağlantı Ayarları
  bool _wifiOnly = false; // Sadece WiFi üzerinden içerik yükle mi?
  bool get wifiOnly => _wifiOnly;

  bool _mobileDataWarning = true; // Mobil veri uyarısı göster mi?
  bool get mobileDataWarning => _mobileDataWarning;

  // Oynatıcı Ayarları
  bool _autoPlayNextEpisode = true; // Sonraki bölümü otomatik oynat?
  bool get autoPlayNextEpisode => _autoPlayNextEpisode;

  bool _rememberWatchPosition = true; // İzleme konumunu hatırla?
  bool get rememberWatchPosition => _rememberWatchPosition;

  // Hata mesajı
  String? _error;
  String? get error => _error;

  // Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Tema değiştir
  /// 
  /// [newTheme]: Yeni tema (light, dark, system)
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTheme('dark');
  /// ```
  Future<void> setTheme(String newTheme) async {
    _theme = newTheme;
    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setString('theme', newTheme);
    } catch (e) {
      _error = 'Tema kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Dil değiştir
  /// 
  /// [newLanguage]: Yeni dil (tr, en)
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setLanguage('en');
  /// ```
  Future<void> setLanguage(String newLanguage) async {
    _language = newLanguage;
    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setString('language', newLanguage);
    } catch (e) {
      _error = 'Dil kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Bildirimleri aç/kapat
  /// 
  /// [enabled]: Açık mı?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setNotifications(false);
  /// ```
  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setBool('notifications_enabled', enabled);
    } catch (e) {
      _error = 'Bildirimler kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// TV Player ayarlarını güncelle
  /// 
  /// [fullscreen]: Tam ekranda başlasın mı?
  /// [channelListPosition]: Kanal listesi konumu
  /// [opacity]: Kanal listesi şeffaflığı
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTvPlayerSettings(
  ///   fullscreen: false,
  ///   channelListPosition: 'left',
  /// );
  /// ```
  Future<void> setTvPlayerSettings({
    bool? fullscreen,
    String? channelListPosition,
    String? opacity,
  }) async {
    if (fullscreen != null) _tvPlayerFullscreen = fullscreen;
    if (channelListPosition != null) _tvChannelListPosition = channelListPosition;
    if (opacity != null) _tvChannelListOpacity = opacity;

    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setBool('tv_fullscreen', _tvPlayerFullscreen);
      // await _preferences.setString('tv_list_position', _tvChannelListPosition);
    } catch (e) {
      _error = 'TV Player ayarları kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Film listeleme ayarlarını güncelle
  /// 
  /// [viewMode]: Görüntü modu (list, grid)
  /// [perPage]: Sayfa başına film sayısı
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setMovieSettings(
  ///   viewMode: 'list',
  ///   perPage: 20,
  /// );
  /// ```
  Future<void> setMovieSettings({
    String? viewMode,
    int? perPage,
  }) async {
    if (viewMode != null) _movieViewMode = viewMode;
    if (perPage != null) _moviesPerPage = perPage;

    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setString('movie_view_mode', _movieViewMode);
      // await _preferences.setInt('movies_per_page', _moviesPerPage);
    } catch (e) {
      _error = 'Film ayarları kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Varsayılan sekmeyi ayarla
  /// 
  /// [tab]: Sekme adı (tv, radio, movies, chat, settings)
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setDefaultTab('movies');
  /// ```
  Future<void> setDefaultTab(String tab) async {
    _defaultTab = tab;
    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setString('default_tab', tab);
    } catch (e) {
      _error = 'Varsayılan sekme kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Bağlantı ayarlarını güncelle
  /// 
  /// [wifiOnly]: Sadece WiFi mi?
  /// [mobileWarning]: Mobil veri uyarısı göster mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setConnectionSettings(
  ///   wifiOnly: true,
  ///   mobileWarning: false,
  /// );
  /// ```
  Future<void> setConnectionSettings({
    bool? wifiOnly,
    bool? mobileWarning,
  }) async {
    if (wifiOnly != null) _wifiOnly = wifiOnly;
    if (mobileWarning != null) _mobileDataWarning = mobileWarning;

    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setBool('wifi_only', _wifiOnly);
      // await _preferences.setBool('mobile_warning', _mobileDataWarning);
    } catch (e) {
      _error = 'Bağlantı ayarları kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Oynatıcı ayarlarını güncelle
  /// 
  /// [autoPlayNextEpisode]: Sonraki bölümü otomatik oynat?
  /// [rememberPosition]: İzleme konumunu hatırla?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setPlayerSettings(
  ///   autoPlayNextEpisode: false,
  ///   rememberPosition: true,
  /// );
  /// ```
  Future<void> setPlayerSettings({
    bool? autoPlayNextEpisode,
    bool? rememberPosition,
  }) async {
    if (autoPlayNextEpisode != null) _autoPlayNextEpisode = autoPlayNextEpisode;
    if (rememberPosition != null) _rememberWatchPosition = rememberPosition;

    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'a kaydet
      // await _preferences.setBool('auto_play_next', _autoPlayNextEpisode);
      // await _preferences.setBool('remember_position', _rememberWatchPosition);
    } catch (e) {
      _error = 'Oynatıcı ayarları kaydedilirken hata: $e';
      notifyListeners();
    }
  }

  /// Tüm ayarları sıfırla
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.resetAllSettings();
  /// ```
  Future<void> resetAllSettings() async {
    _theme = 'light';
    _language = 'tr';
    _notificationsEnabled = true;
    _tvPlayerFullscreen = true;
    _tvChannelListPosition = 'right';
    _tvChannelListOpacity = 'transparent';
    _radioPlayerMinimize = true;
    _movieViewMode = 'grid';
    _moviesPerPage = 10;
    _defaultTab = 'tv';
    _wifiOnly = false;
    _mobileDataWarning = true;
    _autoPlayNextEpisode = true;
    _rememberWatchPosition = true;
    _error = null;
    notifyListeners();

    try {
      // SharedPreferences'ı temizle
      // await _preferences.clear();
    } catch (e) {
      _error = 'Ayarlar sıfırlanırken hata: $e';
      notifyListeners();
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
