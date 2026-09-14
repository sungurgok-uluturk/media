import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';

/// Film/Dizi Repository
/// 
/// Film ve dizileriyle ilgili tüm veri işlemlerini yönetir.
/// API servisi üzerinden Supabase'e bağlanır.
/// 
/// Bu repository film listeleme, detay getirme, yorum yönetimi vb.
/// tüm film operasyonlarını içerir.

class MovieRepository {
  final ApiService _apiService = ApiService();
  static const String _moviesEndpoint = '/movies';
  static const String _genresEndpoint = '/movie-genres';
  static const String _commentsEndpoint = '/movie-comments';
  static const String _seasonsEndpoint = '/movie-seasons';
  static const String _episodesEndpoint = '/movie-episodes';

  /// Tüm filtreleri sıfırla ve filmleri getir
  /// 
  /// [contentType]: İçerik türü (cinema, series) - NULL ise tümü
  /// [genreId]: Tür ID - NULL ise tümü
  /// [limit]: Kaç film getirileceği (default: 10)
  /// [offset]: Kaç film atlanacağı (pagination için)
  /// [sortBy]: Sıralama kriteri (created_at, average_rating)
  /// 
  /// Returns: Film listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final movies = await movieRepository.getAllMovies(
  ///   contentType: 'cinema',
  ///   limit: 20,
  /// );
  /// ```
  Future<List<Movie>> getAllMovies({
    String? contentType,
    int? genreId,
    int limit = 10,
    int offset = 0,
    String sortBy = 'created_at',
  }) async {
    try {
      final queryParams = {
        'is_active': true,
        'limit': limit,
        'offset': offset,
        'order': '$sortBy.desc',
      };

      // İçerik türü filtresi ekle
      if (contentType != null) {
        queryParams['content_type'] = 'eq.$contentType';
      }

      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Film listesi getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Belirli bir filmi ID'ye göre getir
  /// 
  /// [movieId]: Film ID
  /// 
  /// Returns: Film detayları
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
      print('Film detay getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Tür ID'ye göre filmleri getir
  /// 
  /// [genreId]: Tür ID
  /// [contentType]: İçerik türü (cinema, series) - opsiyonel
  /// 
  /// Returns: Tüne ait film listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final scifiMovies = await movieRepository.getMoviesByGenre(2); // Bilim Kurgu
  /// ```
  Future<List<Movie>> getMoviesByGenre(
    int genreId, {
    String? contentType,
  }) async {
    try {
      final queryParams = {
        'genre_ids': 'cs.{$genreId}', // Supabase array query
        'is_active': true,
      };

      if (contentType != null) {
        queryParams['content_type'] = 'eq.$contentType';
      }

      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Türe göre film getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film arama
  /// 
  /// [query]: Aranacak kelime (başlık veya açıklamada)
  /// [contentType]: İçerik türü filtresi (opsiyonel)
  /// 
  /// Returns: Arama sonuçları
  /// 
  /// Örnek:
  /// ```dart
  /// final results = await movieRepository.searchMovies('Matrix');
  /// ```
  Future<List<Movie>> searchMovies(
    String query, {
    String? contentType,
  }) async {
    try {
      final queryParams = {
        'or': '(title.ilike.%$query%,description.ilike.%$query%)',
        'is_active': true,
        'limit': 50,
      };

      if (contentType != null) {
        queryParams['content_type'] = 'eq.$contentType';
      }

      final response = await _apiService.get(
        _moviesEndpoint,
        queryParameters: queryParams,
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Film arama hatası: ${e.message}');
      rethrow;
    }
  }

  /// Tüm türleri getir
  /// 
  /// Returns: Tür listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final genres = await movieRepository.getAllGenres();
  /// ```
  Future<List<Map<String, dynamic>>> getAllGenres() async {
    try {
      final response = await _apiService.get(_genresEndpoint);
      final data = response['data'] as List?;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Türler getirme hatası: ${e.message}');
      return [];
    }
  }

  /// Dizi sezonlarını getir
  /// 
  /// [movieId]: Dizi (film) ID
  /// 
  /// Returns: Sezon listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final seasons = await movieRepository.getSeasons(1);
  /// ```
  Future<List<MovieSeason>> getSeasons(int movieId) async {
    try {
      final response = await _apiService.get(
        '$_seasonsEndpoint?movie_id=eq.$movieId',
        queryParameters: {'order': 'season_number.asc'},
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => MovieSeason.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Sezonlar getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Sezon bölümlerini getir
  /// 
  /// [seasonId]: Sezon ID
  /// 
  /// Returns: Bölüm listesi
  /// 
  /// Örnek:
  /// ```dart
  /// final episodes = await movieRepository.getEpisodes(1);
  /// ```
  Future<List<MovieEpisode>> getEpisodes(int seasonId) async {
    try {
      final response = await _apiService.get(
        '$_episodesEndpoint?season_id=eq.$seasonId',
        queryParameters: {'order': 'episode_number.asc'},
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return data
          .map((item) => MovieEpisode.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Bölümler getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film yorumlarını getir
  /// 
  /// [movieId]: Film ID
  /// [limit]: Kaç yorum getirileceği
  /// [offset]: Kaç yorum atlanacağı
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
          'is_deleted': 'eq.false',
          'limit': limit,
          'offset': offset,
          'order': 'created_at.desc',
        },
      );

      final data = response['data'] as List?;
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      print('Yorumlar getirme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yorum ekle
  /// 
  /// [movieId]: Film ID
  /// [userId]: Yorum yapan kullanıcı ID
  /// [commentText]: Yorum metni
  /// [rating]: Puan (1-10)
  /// 
  /// Returns: Oluşturulan yorum
  /// 
  /// Örnek:
  /// ```dart
  /// final comment = await movieRepository.addComment(
  ///   movieId: 1,
  ///   userId: 'user-id',
  ///   commentText: 'Harika bir film!',
  ///   rating: 9,
  /// );
  /// ```
  Future<Map<String, dynamic>> addComment({
    required int movieId,
    required String userId,
    required String commentText,
    int? rating,
  }) async {
    try {
      final response = await _apiService.post(
        _commentsEndpoint,
        data: {
          'movie_id': movieId,
          'user_id': userId,
          'comment_text': commentText,
          'rating': rating,
        },
      );

      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Yorum ekleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Yorum beğeni/dislike ekle
  /// 
  /// [commentId]: Yorum ID
  /// [userId]: Kullanıcı ID
  /// [reactionType]: Reaksiyon türü (like, dislike)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.addCommentReaction(
  ///   commentId: 1,
  ///   userId: 'user-id',
  ///   reactionType: 'like',
  /// );
  /// ```
  Future<void> addCommentReaction({
    required int commentId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _apiService.post(
        '/movie-comment-reactions',
        data: {
          'comment_id': commentId,
          'user_id': userId,
          'reaction_type': reactionType,
        },
      );
    } on DioException catch (e) {
      print('Reaksiyon ekleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film Rapor Et
  /// 
  /// [movieId]: Rapor edilen film ID
  /// [description]: Sorun açıklaması
  /// [userId]: Raporlayan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieRepository.reportMovie(
  ///   movieId: 1,
  ///   description: 'Bozuk link',
  ///   userId: 'user-id',
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
      print('Film rapor etme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film ekle (Yönetici işlemi)
  /// 
  /// [movie]: Eklenecek film
  /// 
  /// Returns: Oluşturulan film
  Future<Movie> createMovie(Movie movie) async {
    try {
      final response = await _apiService.post(
        _moviesEndpoint,
        data: movie.toJson(),
      );

      return Movie.fromJson(response as Map<String, dynamic>);
    } on DioException catch (e) {
      print('Film oluşturma hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film güncelle (Yönetici işlemi)
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
      print('Film güncelleme hatası: ${e.message}');
      rethrow;
    }
  }

  /// Film sil (Yönetici işlemi)
  Future<void> deleteMovie(int movieId) async {
    try {
      await _apiService.delete(
        '$_moviesEndpoint?id=eq.$movieId',
      );
    } on DioException catch (e) {
      print('Film silme hatası: ${e.message}');
      rethrow;
    }
  }
}
