import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';

/// Versiyon Yönetimi Provider
/// 
/// Uygulamanın versiyon kontrolü ve güncelleme bildirimlerini yönetir.
/// Her açılışta Supabase'de saklı versiyon kontrolü ile karşılaştırır.
/// 
/// Akış:
/// 1. Uygulama açılışında versiyon kontrol edilir
/// 2. Eğer yeni versiyon varsa:
///    - Zorunlu mu değil mi kontrol edilir
///    - Güncelleme mesajı gösterilir
///    - Yeni sürüm indirme linki sağlanır
/// 3. Güncelleme yapıldıktan sonra 'Yenilikleri Gör' ekranı açılır

class VersionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Mevcut versiyon
  String _currentVersion = '1.0.0';
  String get currentVersion => _currentVersion;

  /// Sunucu'da gereken minimum versiyon
  String _requiredVersion = '1.0.0';
  String get requiredVersion => _requiredVersion;

  /// Yeni versiyon mevcut mu?
  bool _updateAvailable = false;
  bool get updateAvailable => _updateAvailable;

  /// Güncelleme zorunlu mu?
  bool _isForceUpdate = false;
  bool get isForceUpdate => _isForceUpdate;

  /// Güncelleme changelog'u
  String _changelog = '';
  String get changelog => _changelog;

  /// İndirme linki
  String _downloadUrl = '';
  String get downloadUrl => _downloadUrl;

  /// Telegram kanalı linki (hosting yoksa buradan indir)
  String _telegramChannelUrl = '';
  String get telegramChannelUrl => _telegramChannelUrl;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Uygulama ilk kez açıldı mı? (Yenilikleri Gör ekranını göstermek için)
  bool _isFirstLaunchAfterUpdate = false;
  bool get isFirstLaunchAfterUpdate => _isFirstLaunchAfterUpdate;

  VersionProvider() {
    _initializeVersion();
  }

  /// Versiyon bilgisini başlat
  Future<void> _initializeVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
  }

  /// Versiyon kontrolü yap
  /// 
  /// Supabase'den sistem versiyonunu alır ve mevcut versiyon ile karşılaştırır.
  /// 
  /// Akış:
  /// 1. Supabase'den en son versiyonu çek
  /// 2. Mevcut versiyon ile karşılaştır
  /// 3. Gerekirse güncelleme bildirimini göster
  /// 4. Eğer ilk güncelleme ise 'Yenilikleri Gör' ekranını işaretle
  /// 
  /// Örnek:
  /// ```dart
  /// await versionProvider.checkForUpdates();
  /// if (versionProvider.updateAvailable) {
  ///   // Güncelleme ekranı göster
  /// }
  /// ```
  Future<void> checkForUpdates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Supabase'den sistem versiyonunu al
      final response = await _apiService.get(
        '/system/version',
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        _error = 'Versiyon bilgisi alınamadı';
        return;
      }

      _requiredVersion = data['required_version'] ?? '1.0.0';
      final latestVersion = data['current_version'] ?? '1.0.0';
      _changelog = data['changelog'] ?? '';
      _isForceUpdate = data['force_update'] ?? false;
      _downloadUrl = data['download_url'] ?? '';
      _telegramChannelUrl = data['telegram_channel_url'] ?? '';

      // Versiyon karşılaştırması
      _updateAvailable = _compareVersions(latestVersion, _currentVersion) > 0;

      // Mevcut versiyon minimum gerekli versiyon'dan küçükse
      if (_compareVersions(_currentVersion, _requiredVersion) < 0) {
        _isForceUpdate = true;
      }

      // İlk kez güncelleme durumunu kontrol et
      if (_updateAvailable) {
        _isFirstLaunchAfterUpdate = true;
      }

      _error = null;
    } catch (e) {
      _error = 'Versiyon kontrolü hatası: $e';
      print('Version check error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// İki versiyon numarasını karşılaştır
  /// 
  /// Returns:
  /// - 1: version1 > version2
  /// - 0: version1 == version2
  /// - -1: version1 < version2
  /// 
  /// Örnek:
  /// ```dart
  /// final result = _compareVersions('2.0.0', '1.0.0'); // 1 döndürür
  /// ```
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // Uzunluk eşitle
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }

  /// Yenilikleri gösterildi olarak işaretle
  /// 
  /// Böylece uygulama sonraki açılışında bu ekranı göstermez.
  void markChangelogAsViewed() {
    _isFirstLaunchAfterUpdate = false;
    notifyListeners();
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
