import 'package:dio/dio.dart';
import '../models/radio_channel_model.dart';
import '../services/api_service.dart';

/// Radyo Kanalları Repository
/// 
/// Radyo kanallarıyla ilgili tüm veri işlemlerini yönetir.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Özellikler:
/// - Radyo kanallarının listelenmesi
/// - Arama fonksiyonu
/// - Kanal ekleme/güncelleme/silme (yönetici)
/// - Rapor etme

class RadioRepository {
  final ApiService _apiService = ApiService();
  static const String _endpoint = '/radio-channels';

  /// Tüm aktif radyo kanallarını getir
  /// 
  /// [limit]: Kaç kanal getirileceği (default: 10)
  /// [offset]: Kaç kanal atlanacağı (pagination için)
  /// [sortBy]: Sıralama (name, created_at)
  /// 
  /// Returns: Radyo kanallarının listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final channels = await radioRepository.getAllChannels(limit: 20);
  /// ```
  Future<List<RadioChannel>> getAllChannels({
    int limit = 10,
    int offset = 0,
    String sortBy = 'channel_name',
  }) async {
    try {
      final response = await _apiService.get(
        _endpoint,
        queryParameters: {
          'is_active': true,
          'limit': limit,
          'offset': offset,
          'order': '$sortBy.asc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => RadioChannel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Radyo kanalları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Belirli bir radyo kanalını ID'ye göre getir
  /// 
  /// [channelId]: Kanal ID
  /// 
  /// Returns: Radyo kanalı
  /// 
  /// Örnek:
  /// ```dart
  /// final channel = await radioRepository.getChannelById(1);
  /// ```
  Future<RadioChannel?> getChannelById(int channelId) async {
    try {
      final response = await _apiService.get(
        '$_endpoint?id=eq.$channelId',
      );

      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return null;

      return RadioChannel.fromJson(data[0] as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Radyo kanal getirme hatası (ID: $channelId): ${e.message}');
      rethrow;
    }
  }

  /// Radyo kanallarında arama yap
  /// 
  /// [query]: Aranacak kelime (kanal adında)
  /// [limit]: Maksimum sonuç sayısı
  /// 
  /// Returns: Arama sonuçları
  /// 
  /// Örnek:
  /// ```dart
  /// final results = await radioRepository.searchChannels('TRT');
  /// ```
  Future<List<RadioChannel>> searchChannels(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        _endpoint,
        queryParameters: {
          'channel_name': 'ilike.*$query*',
          'is_active': true,
          'limit': limit,
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => RadioChannel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Radyo kanal arama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kategoriye göre radyo kanallarını getir
  /// 
  /// [category]: Kategori adı (Müzik, Haber, Spor vb)
  /// 
  /// Returns: Kategoriye ait radyo kanallarının listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final newsChannels = await radioRepository.getChannelsByCategory('Haber');
  /// ```
  Future<List<RadioChannel>> getChannelsByCategory(String category) async {
    try {
      final response = await _apiService.get(
        _endpoint,
        queryParameters: {
          'category': 'eq.$category',
          'is_active': true,
          'order': 'channel_name.asc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => RadioChannel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Kategoriye göre radyo kanal getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Radyo kanalı ekle (Yönetici işlemi)
  /// 
  /// [channel]: Eklenecek kanal bilgileri
  /// 
  /// Returns: Oluşturulan kanal
  /// 
  /// Örnek:
  /// ```dart
  /// final newChannel = RadioChannel(
  ///   id: 0,
  ///   channelName: 'Yeni Radyo',
  ///   streamUrl: 'https://stream.example.com/radio.m3u8',
  ///   category: 'Müzik',
  ///   isActive: true,
  ///   createdAt: DateTime.now(),
  ///   updatedAt: DateTime.now(),
  /// );
  /// final created = await radioRepository.createChannel(newChannel);
  /// ```
  Future<RadioChannel> createChannel(RadioChannel channel) async {
    try {
      final response = await _apiService.post(
        _endpoint,
        data: channel.toJson(),
      );

      return RadioChannel.fromJson(response as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Radyo kanal oluşturma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Radyo kanalını güncelle (Yönetici işlemi)
  /// 
  /// [channelId]: Güncellenecek kanal ID
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Örnek:
  /// ```dart
  /// await radioRepository.updateChannel(1, {
  ///   'channel_name': 'Güncellenmiş Adı',
  ///   'stream_url': 'https://new-stream.url/radio.m3u8'
  /// });
  /// ```
  Future<void> updateChannel(
    int channelId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _apiService.patch(
        '$_endpoint?id=eq.$channelId',
        data: updates,
      );
    } on DioException catch (e) {
      print('Radyo kanal güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Radyo kanalı sil (Yönetici işlemi)
  /// 
  /// [channelId]: Silinecek kanal ID
  /// 
  /// Örnek:
  /// ```dart
  /// await radioRepository.deleteChannel(1);
  /// ```
  Future<void> deleteChannel(int channelId) async {
    try {
      await _apiService.delete(
        '$_endpoint?id=eq.$channelId',
      );
    } on DioException catch (e) {
      print('Radyo kanal silme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Radyo Kanalı Rapor Etme
  /// 
  /// [channelId]: Rapor edilen kanal ID
  /// [description]: Sorun açıklaması
  /// [userId]: Raporlayan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await radioRepository.reportChannel(
  ///   channelId: 1,
  ///   description: 'Yayın kesildi',
  ///   userId: 'user-id',
  /// );
  /// ```
  Future<void> reportChannel({
    required int channelId,
    required String description,
    required String userId,
  }) async {
    try {
      await _apiService.post(
        '/reports',
        data: {
          'report_type': 'radio',
          'reported_content_id': channelId.toString(),
          'description': description,
          'user_id': userId,
        },
      );
    } on DioException catch (e) {
      print('Radyo kanal rapor etme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Kanal kategorilerini getir
  /// 
  /// Returns: Tüm radyo kategorileri
  /// 
  /// Örnek:
  /// ```dart
  /// final categories = await radioRepository.getCategories();
  /// ```
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiService.get(
        '$_endpoint/categories',
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data.cast<String>();
    } on DioException catch (e) {
      print('Radyo kategorileri getirme hatası: ${e.message}');
      rethrow;
    }
  }
}
