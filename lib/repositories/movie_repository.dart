import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';

/// Film/Dizi Repository
/// 
/// Film ve dizilerle ilgili tüm veri işlemlerini yönetir.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Özellikler:
/// - Film ve dizi listeleme (kategoriye göre)
/// - Türlere göre filtreleme
/// - Film detayları ve yorumları
/// - Sezon ve bölüm yönetimi
/// - Yorum sistemi
/// - Puan sistemi

class MovieRepository {
  final ApiService _apiService = ApiService();
  static const String _moviesEndpoint = '/movies';
  static const String _genresEndpoint = '/movie-genres';
  static const String _commentsEndpoint = '/movie-comments';

  /// Filmler/Dizileri getir
  /// 
  /// [contentType]: 'cinema' (Sinema) veya 'series' (Dizi)
  /// [limit]: Kaç film getirileceği (default: 10)
  /// [offset]: Kaç film atlanacağı (pagination için)
  /// [sortBy]: Sıralama (created_at, average_rating, title)
  /// 
  /// Returns: Film/dizi listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final movies = await movieRepository.getMovies(
  ///   contentType: 'cinema',
  ///   limit: 20
  /// );
  /// ```
  Future<List<Movie>> getMovies({
    required String contentType,
    int limit = 10,
    int offset = 0,
    String sortBy = 'created_at',
  }) async {
    try {
      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: {
          'content_type': 'eq.$contentType',
          'is_active': true,
          'limit': limit,
          'offset': offset,
          'order': '$sortBy.desc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Film/Dizi getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Belirli bir filmi/diziyi ID'ye göre getir
  /// 
  /// [movieId]: Film/Dizi ID
  /// 
  /// Returns: Film/Dizi
  /// 
  /// Örnek:
  /// ```dart
  /// final movie = await movieRepository.getMovieById(1);
  /// ```
  Future<Movie?> getMovieById(int movieId) async {
    try {
      final response = await _apiService.get(
        '$_moviesEndpoint?id=eq.$movieId',
      );

      final data = response['data'] as List?;
      if (data == null || data.isEmpty) return null;

      return Movie.fromJson(data[0] as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Film/Dizi getirme hatası (ID: $movieId): ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi türlerine göre getir
  /// 
  /// [contentType]: 'cinema' veya 'series'
  /// [genreIds]: Tür ID'leri
  /// [limit]: Limit
  /// [offset]: Offset
  /// 
  /// Returns: Filtrelenmiş film/dizi listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final movies = await movieRepository.getMoviesByGenres(
  ///   contentType: 'cinema',
  ///   genreIds: [1, 2], // Fantastik, Bilim Kurgu
  /// );
  /// ```
  Future<List<Movie>> getMoviesByGenres({
    required String contentType,
    required List<int> genreIds,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      // Genre ID'leri komma ile ayırarak query oluştur
      final genreQuery = genreIds.join(',');

      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: {
          'content_type': 'eq.$contentType',
          'genre_ids': 'cs.{$genreQuery}', // contains any
          'is_active': true,
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Türlerine göre film/dizi getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi ara
  /// 
  /// [query]: Aranacak kelime (başlıkta)
  /// [limit]: Maksimum sonuç sayısı
  /// 
  /// Returns: Arama sonuçları
  /// 
  /// Örnek:
  /// ```dart
  /// final results = await movieRepository.searchMovies('Matrix');
  /// ```
  Future<List<Movie>> searchMovies(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: {
          'title': 'ilike.*$query*',
          'is_active': true,
          'limit': limit,
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Film/Dizi arama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Tüm film türlerini getir
  /// 
  /// Returns: Kullanılabilir film türleri
  /// 
  /// Örnek:
  /// ```dart
  /// final genres = await movieRepository.getGenres();
  /// ```
  Future<List<Map<String, dynamic>>> getGenres() async {
    try {
      final response = await _apiService.get(_genresEndpoint);

      final data = response['data'] as List?;
      if (data == null) return [];

      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      print('Film türleri getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Dizi sezonlarını getir
  /// 
  /// [movieId]: Dizi ID
  /// 
  /// Returns: Sezonlar listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final seasons = await movieRepository.getSeasons(1);
  /// ```
  Future<List<MovieSeason>> getSeasons(int movieId) async {
    try {
      final response = await _apiService.get(
        '$_moviesEndpoint/$movieId/seasons',
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => MovieSeason.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Dizi sezonları getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sezonun bölümlerini getir
  /// 
  /// [seasonId]: Sezon ID
  /// 
  /// Returns: Bölümler listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final episodes = await movieRepository.getEpisodes(1);
  /// ```
  Future<List<MovieEpisode>> getEpisodes(int seasonId) async {
    try {
      final response = await _apiService.get(
        '/movie-seasons/$seasonId/episodes',
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => MovieEpisode.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Dizi bölümleri getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi yorumlarını getir
  /// 
  /// [movieId]: Film/Dizi ID
  /// [limit]: Kaç yorum getirileceği
  /// [offset]: Pagination offset
  /// 
  /// Returns: Yorum listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final comments = await movieRepository.getComments(1, limit: 20);
  /// ```
  Future<List<Map<String, dynamic>>> getComments(
    int movieId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '$_commentsEndpoint?movie_id=eq.$movieId',
        queryParameters: {
          'is_deleted': false,
          'limit': limit,
          'offset': offset,
          'order': 'created_at.desc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      print('Film/Dizi yorum getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi'ye yorum yap
  /// 
  /// [movieId]: Film/Dizi ID
  /// [userId]: Yorum yapan kullanıcı ID
  /// [commentText]: Yorum metni
  /// [rating]: Puan (1-10, opsiyonel)
  /// 
  /// Returns: Yorum başarı durumu
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.addComment(
  ///   movieId: 1,
  ///   userId: 'user-123',
  ///   commentText: 'Müthiş bir film!',
  ///   rating: 9,
  /// );
  /// ```
  Future<bool> addComment({
    required int movieId,
    required String userId,
    required String commentText,
    int? rating,
  }) async {
    try {
      await _apiService.post(
        _commentsEndpoint,
        data: {
          'movie_id': movieId,
          'user_id': userId,
          'comment_text': commentText,
          'rating': rating,
        },
      );
      return true;
    } on DioException catch (e) {
      print('Yorum ekleme hatası: ${e.message}');
      return false;
    }
  }

  /// Yoruma beğeni ekle
  /// 
  /// [commentId]: Yorum ID
  /// [userId]: Beğenen kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.likeComment(commentId: 1, userId: 'user-123');
  /// ```
  Future<bool> likeComment({
    required int commentId,
    required String userId,
  }) async {
    try {
      await _apiService.post(
        '/movie-comment-reactions',
        data: {
          'comment_id': commentId,
          'user_id': userId,
          'reaction_type': 'like',
        },
      );
      return true;
    } on DioException catch (e) {
      print('Beğeni ekleme hatası: ${e.message}');
      return false;
    }
  }

  /// Film/Dizi ekle (Yönetici işlemi)
  /// 
  /// [movie]: Eklenecek film/dizi bilgileri
  /// 
  /// Returns: Oluşturulan film/dizi
  /// 
  /// Örnek:
  /// ```dart
  /// final newMovie = Movie(
  ///   id: 0,
  ///   title: 'Yeni Film',
  ///   contentType: 'cinema',
  ///   isEncrypted: false,
  ///   totalComments: 0,
  ///   averageRating: 0,
  ///   totalRatings: 0,
  ///   isActive: true,
  ///   createdAt: DateTime.now(),
  ///   updatedAt: DateTime.now(),
  /// );
  /// final created = await movieRepository.createMovie(newMovie);
  /// ```
  Future<Movie> createMovie(Movie movie) async {
    try {
      final response = await _apiService.post(
        _moviesEndpoint,
        data: movie.toJson(),
      );

      return Movie.fromJson(response as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Film/Dizi oluşturma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi güncelle (Yönetici işlemi)
  /// 
  /// [movieId]: Güncellenecek film/dizi ID
  /// [updates]: Güncellenecek alanlar
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.updateMovie(1, {
  ///   'title': 'Güncellenmiş Başlık',
  ///   'is_encrypted': true,
  /// });
  /// ```
  Future<void> updateMovie(
    int movieId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _apiService.patch(
        '$_moviesEndpoint?id=eq.$movieId',
        data: updates,
      );
    } on DioException catch (e) {
      print('Film/Dizi güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi sil (Yönetici işlemi)
  /// 
  /// [movieId]: Silinecek film/dizi ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.deleteMovie(1);
  /// ```
  Future<void> deleteMovie(int movieId) async {
    try {
      await _apiService.delete(
        '$_moviesEndpoint?id=eq.$movieId',
      );
    } on DioException catch (e) {
      print('Film/Dizi silme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film/Dizi rapor et
  /// 
  /// [movieId]: Rapor edilen film/dizi ID
  /// [description]: Sorun açıklaması
  /// [userId]: Raporlayan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.reportMovie(
  ///   movieId: 1,
  ///   description: 'Link bozuk',
  ///   userId: 'user-123',
  /// );
  /// ```
  Future<void> reportMovie({
    required int movieId,
    required String description,
    required String userId,
  }) async {
    try {
      await _apiService.post(
        '/reports',
        data: {
          'report_type': 'movie',
          'reported_content_id': movieId.toString(),
          'description': description,
          'user_id': userId,
        },
      );
    } on DioException catch (e) {
      print('Film/Dizi rapor etme hatası: ${e.message}');
      rethrow;
    }
  }
}
