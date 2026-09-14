import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../repositories/movie_repository.dart';

/// Film/Dizi Provider
/// 
/// Film ve dizilerle ilgili tüm state yönetimini yapar.
/// Listeleme, filtreleme, detay görüntüleme vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikler:
/// - Film/Dizi listeleme (kategoriye göre)
/// - Tür filtreleme
/// - Arama desteği
/// - Yorum sistemi
/// - Sezon ve bölüm yönetimi (diziler için)
/// - Pagination desteği

class MovieProvider extends ChangeNotifier {
  final MovieRepository _movieRepository = MovieRepository();

  /// Tüm filmler/diziler
  List<Movie> _movies = [];
  List<Movie> get movies => _movies;

  /// Seçili film/dizi
  Movie? _selectedMovie;
  Movie? get selectedMovie => _selectedMovie;

  /// Seçili film/dizinin sezonları (dizi için)
  List<MovieSeason> _seasons = [];
  List<MovieSeason> get seasons => _seasons;

  /// Seçili sezonun bölümleri (dizi için)
  List<MovieEpisode> _episodes = [];
  List<MovieEpisode> get episodes => _episodes;

  /// Seçili film/dizinin yorumları
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> get comments => _comments;

  /// Tüm türler
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> get genres => _genres;

  /// Seçili tür ID'leri
  List<int> _selectedGenreIds = [];
  List<int> get selectedGenreIds => _selectedGenreIds;

  /// İçerik türü (cinema, series)
  String _contentType = 'cinema';
  String get contentType => _contentType;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  /// Arama sorgusu
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Listeleme görünümü (list, grid)
  String _viewMode = 'grid';
  String get viewMode => _viewMode;

  /// Tüm filmler/dizileri yükle
  /// 
  /// [contentType]: 'cinema' (Sinema) veya 'series' (Dizi)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadMovies(contentType: 'cinema');
  /// ```
  Future<void> loadMovies({required String contentType}) async {
    _contentType = contentType;
    _currentPage = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final movies = await _movieRepository.getMovies(
        contentType: contentType,
        limit: 10,
        offset: 0,
      );
      _movies = movies;
      _error = null;
    } catch (e) {
      _error = 'Filmler yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Türlere göre filmler/dizileri yükle
  /// 
  /// [contentType]: İçerik türü
  /// [genreIds]: Tür ID'leri
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadMoviesByGenres(
  ///   contentType: 'cinema',
  ///   genreIds: [1, 2], // Fantastik, Bilim Kurgu
  /// );
  /// ```
  Future<void> loadMoviesByGenres({
    required String contentType,
    required List<int> genreIds,
  }) async {
    if (genreIds.isEmpty) {
      await loadMovies(contentType: contentType);
      return;
    }

    _contentType = contentType;
    _selectedGenreIds = genreIds;
    _currentPage = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final movies = await _movieRepository.getMoviesByGenres(
        contentType: contentType,
        genreIds: genreIds,
        limit: 10,
        offset: 0,
      );
      _movies = movies;
      _error = null;
    } catch (e) {
      _error = 'Türlerine göre filmler yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filmler/Dizilerde arama yap
  /// 
  /// [query]: Aranacak kelime
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.searchMovies('Matrix');
  /// ```
  Future<void> searchMovies(String query) async {
    _searchQuery = query;
    _currentPage = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await loadMovies(contentType: _contentType);
      } else {
        final results = await _movieRepository.searchMovies(query);
        _movies = results;
        _error = null;
      }
    } catch (e) {
      _error = 'Arama sırasında hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Türleri yükle
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadGenres();
  /// ```
  Future<void> loadGenres() async {
    try {
      _genres = await _movieRepository.getGenres();
      notifyListeners();
    } catch (e) {
      print('Türler yüklenirken hata: $e');
    }
  }

  /// Film/Dizi seç ve detaylarını yükle
  /// 
  /// [movie]: Seçilecek film/dizi
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.selectMovie(movie);
  /// ```
  Future<void> selectMovie(Movie movie) async {
    _selectedMovie = movie;
    _isLoading = true;
    notifyListeners();

    try {
      // Yorumları yükle
      await loadComments(movie.id);

      // Dizi ise sezonları yükle
      if (movie.isSeries) {
        _seasons = await _movieRepository.getSeasons(movie.id);
        if (_seasons.isNotEmpty) {
          // İlk sezonun bölümlerini yükle
          await selectSeason(_seasons[0]);
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Film/Dizi yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sezon seç ve bölümleri yükle (Dizi için)
  /// 
  /// [season]: Seçilecek sezon
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.selectSeason(season);
  /// ```
  Future<void> selectSeason(MovieSeason season) async {
    _isLoading = true;
    notifyListeners();

    try {
      _episodes = await _movieRepository.getEpisodes(season.id);
      _error = null;
    } catch (e) {
      _error = 'Bölümler yüklenirken hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Film/Dizinin yorumlarını yükle
  /// 
  /// [movieId]: Film/Dizi ID
  /// [limit]: Limit
  /// [offset]: Offset
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadComments(movieId);
  /// ```
  Future<void> loadComments(
    int movieId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      _comments = await _movieRepository.getComments(
        movieId,
        limit: limit,
        offset: offset,
      );
      notifyListeners();
    } catch (e) {
      print('Yorumlar yüklenirken hata: $e');
    }
  }

  /// Film/Diziye yorum yap
  /// 
  /// [movieId]: Film/Dizi ID
  /// [userId]: Yorum yapan kullanıcı ID
  /// [commentText]: Yorum metni
  /// [rating]: Puan (1-10, opsiyonel)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.addComment(
  ///   movieId: 1,
  ///   userId: 'user-123',
  ///   commentText: 'Harika bir film!',
  ///   rating: 9,
  /// );
  /// ```
  Future<bool> addComment({
    required int movieId,
    required String userId,
    required String commentText,
    int? rating,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _movieRepository.addComment(
        movieId: movieId,
        userId: userId,
        commentText: commentText,
        rating: rating,
      );

      if (success) {
        // Yorumları yeniden yükle
        await loadComments(movieId);
      }
      return success;
    } catch (e) {
      _error = 'Yorum yapma hatası: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yoruma beğeni ekle
  /// 
  /// [commentId]: Yorum ID
  /// [userId]: Beğenen kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.likeComment(commentId: 1, userId: 'user-123');
  /// ```
  Future<bool> likeComment({
    required int commentId,
    required String userId,
  }) async {
    try {
      return await _movieRepository.likeComment(
        commentId: commentId,
        userId: userId,
      );
    } catch (e) {
      _error = 'Beğeni ekleme hatası: $e';
      return false;
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
  /// await movieProvider.reportMovie(
  ///   movieId: 1,
  ///   description: 'Link bozuk',
  ///   userId: 'user-123',
  /// );
  /// ```
  Future<bool> reportMovie({
    required int movieId,
    required String description,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _movieRepository.reportMovie(
        movieId: movieId,
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

  /// Daha fazla film/dizi yükle (pagination)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadMoreMovies();
  /// ```
  Future<void> loadMoreMovies() async {
    _currentPage++;
    _isLoading = true;
    notifyListeners();

    try {
      List<Movie> moreMovies;
      if (_selectedGenreIds.isEmpty) {
        moreMovies = await _movieRepository.getMovies(
          contentType: _contentType,
          limit: 10,
          offset: _currentPage * 10,
        );
      } else {
        moreMovies = await _movieRepository.getMoviesByGenres(
          contentType: _contentType,
          genreIds: _selectedGenreIds,
          limit: 10,
          offset: _currentPage * 10,
        );
      }
      _movies.addAll(moreMovies);
      _error = null;
    } catch (e) {
      _error = 'Daha fazla film yüklenirken hata: $e';
      _currentPage--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listeleme görünümünü değiştir (list <-> grid)
  /// 
  /// Örnek:
  /// ```dart
  /// movieProvider.toggleViewMode();
  /// ```
  void toggleViewMode() {
    _viewMode = _viewMode == 'list' ? 'grid' : 'list';
    notifyListeners();
  }

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Tüm veriyi sıfırla
  void reset() {
    _movies = [];
    _selectedMovie = null;
    _seasons = [];
    _episodes = [];
    _comments = [];
    _selectedGenreIds = [];
    _currentPage = 0;
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }
}
