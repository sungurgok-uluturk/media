import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Ayarlar Provider
/// 
/// Uygulama ayarlarını ve kullanıcı tercihlerini yönetir.
/// Tema, dil, oynatıcı ayarları vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikler:
/// - Tema yönetimi (açık/koyu)
/// - Uygulama ayarları
/// - TV Player ayarları
/// - Radyo Player ayarları
/// - Kullanıcı profili düzenleme

class SettingsProvider extends ChangeNotifier {
  /// Tema (light, dark, custom)
  String _theme = 'dark';
  String get theme => _theme;

  /// TV Player başlangıç modu (fullscreen, mini)
  String _tvPlayerStartMode = 'fullscreen';
  String get tvPlayerStartMode => _tvPlayerStartMode;

  /// TV kanal listesi konumu (left, right, bottom, top)
  String _tvChannelListPosition = 'right';
  String get tvChannelListPosition => _tvChannelListPosition;

  /// TV kanal listesi transparanlığı (transparent, opaque)
  String _tvChannelListTransparency = 'opaque';
  String get tvChannelListTransparency => _tvChannelListTransparency;

  /// Başlangıç sekmesi (tv, radio, movie, chat, settings)
  String _startTab = 'tv';
  String get startTab => _startTab;

  /// Bildirimleri etkinleştir/devre dışı bırak
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Radyo arka planda çalmaya devam etsin mi
  bool _radioBackgroundPlayback = true;
  bool get radioBackgroundPlayback => _radioBackgroundPlayback;

  /// Video kalitesi otomatik seçilsin mi
  bool _autoSelectQuality = true;
  bool get autoSelectQuality => _autoSelectQuality;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Ayarları yükle (SharedPreferences veya lokal veritabanından)
  Future<void> loadSettings() async {
    try {
      // TODO: SharedPreferences'ten veya local DB'den yükle
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Ayarlar yüklenirken hata: $e';
      print('Load settings error: $e');
    }
  }

  /// Tema değiştir
  /// 
  /// [newTheme]: Yeni tema (light, dark, custom)
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTheme('dark');
  /// ```
  Future<void> setTheme(String newTheme) async {
    _theme = newTheme;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Tema kaydedilirken hata: $e';
      print('Set theme error: $e');
    }
  }

  /// TV Player başlangıç modunu değiştir
  /// 
  /// [mode]: fullscreen veya mini
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTvPlayerStartMode('fullscreen');
  /// ```
  Future<void> setTvPlayerStartMode(String mode) async {
    _tvPlayerStartMode = mode;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'TV Player ayarı kaydedilirken hata: $e';
      print('Set TV player mode error: $e');
    }
  }

  /// TV kanal listesi konumunu değiştir
  /// 
  /// [position]: left, right, bottom, top
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTvChannelListPosition('left');
  /// ```
  Future<void> setTvChannelListPosition(String position) async {
    _tvChannelListPosition = position;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Kanal listesi konumu kaydedilirken hata: $e';
      print('Set channel list position error: $e');
    }
  }

  /// TV kanal listesi şeffaflığını değiştir
  /// 
  /// [transparency]: transparent veya opaque
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setTvChannelListTransparency('transparent');
  /// ```
  Future<void> setTvChannelListTransparency(String transparency) async {
    _tvChannelListTransparency = transparency;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Şeffaflık kaydedilirken hata: $e';
      print('Set transparency error: $e');
    }
  }

  /// Başlangıç sekmesini değiştir
  /// 
  /// [tabName]: tv, radio, movie, chat, settings
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setStartTab('movie');
  /// ```
  Future<void> setStartTab(String tabName) async {
    _startTab = tabName;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Başlangıç sekmesi kaydedilirken hata: $e';
      print('Set start tab error: $e');
    }
  }

  /// Bildirimleri etkinleştir/devre dışı bırak
  /// 
  /// [enabled]: Etkinleştirilsin mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setNotifications(false);
  /// ```
  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Bildirim ayarı kaydedilirken hata: $e';
      print('Set notifications error: $e');
    }
  }

  /// Radyo arka plan oynatmasını etkinleştir/devre dışı bırak
  /// 
  /// [enabled]: Etkinleştirilsin mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setRadioBackgroundPlayback(true);
  /// ```
  Future<void> setRadioBackgroundPlayback(bool enabled) async {
    _radioBackgroundPlayback = enabled;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Arka plan oynatma ayarı kaydedilirken hata: $e';
      print('Set background playback error: $e');
    }
  }

  /// Video kalitesi otomatik seçilsin mi
  /// 
  /// [enabled]: Otomatik seçilsin mi?
  /// 
  /// Örnek:
  /// ```dart
  /// await settingsProvider.setAutoSelectQuality(false);
  /// ```
  Future<void> setAutoSelectQuality(bool enabled) async {
    _autoSelectQuality = enabled;
    notifyListeners();

    try {
      // TODO: SharedPreferences'e kaydet
      _error = null;
    } catch (e) {
      _error = 'Kalite ayarı kaydedilirken hata: $e';
      print('Set auto quality error: $e');
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
