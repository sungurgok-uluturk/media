import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../repositories/movie_repository.dart';

/// Film/Dizi Provider
/// 
/// Film ve dizilerle ilgili tüm state yönetimini yapar.
/// Film listeleme, arama, detay gösterme, yorum yönetimi vb.
/// 
/// State Management: Provider kullanılır
/// 
/// Özellikleri:
/// - Film listeleme (sinema, dizi)
/// - Türe göre filtreleme
/// - Arama
/// - Yorum yönetimi
/// - Dizi sezonları ve bölümleri
/// - Pagination

class MovieProvider extends ChangeNotifier {
  final MovieRepository _movieRepository = MovieRepository();

  /// Tüm filmler
  List<Movie> _movies = [];
  List<Movie> get movies => _movies;

  /// Arama sonuçları
  List<Movie> _searchResults = [];
  List<Movie> get searchResults => _searchResults;

  /// Seçili film
  Movie? _selectedMovie;
  Movie? get selectedMovie => _selectedMovie;

  /// Seçili filmin sezonları (dizi için)
  List<MovieSeason> _seasons = [];
  List<MovieSeason> get seasons => _seasons;

  /// Seçili sezon
  MovieSeason? _selectedSeason;
  MovieSeason? get selectedSeason => _selectedSeason;

  /// Seçili sezonun bölümleri
  List<MovieEpisode> _episodes = [];
  List<MovieEpisode> get episodes => _episodes;

  /// Seçili bölüm (dizi için oynatma)
  MovieEpisode? _selectedEpisode;
  MovieEpisode? get selectedEpisode => _selectedEpisode;

  /// Film yorumları
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> get comments => _comments;

  /// Tüm türler
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> get genres => _genres;

  /// Seçili tür
  Map<String, dynamic>? _selectedGenre;
  Map<String, dynamic>? get selectedGenre => _selectedGenre;

  /// İçerik türü (cinema, series)
  String? _selectedContentType;
  String? get selectedContentType => _selectedContentType;

  /// Yükleme durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Arama yükleme durumu
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  /// Hata mesajı
  String? _error;
  String? get error => _error;

  /// Sayfa numarası (pagination)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  MovieProvider() {
    _initialize();
  }

  /// Provider'ı başlat
  Future<void> _initialize() async {
    await _loadGenres();
  }

  /// Türleri yükle
  Future<void> _loadGenres() async {
    try {
      _genres = await _movieRepository.getAllGenres();
      notifyListeners();
    } catch (e) {
      print('Load genres error: $e');
    }
  }

  /// Tüm filmleri yükle
  /// 
  /// [contentType]: İçerik türü filtresi (cinema, series)
  /// [forceRefresh]: Öncekini yoksay ve yeniden yükle
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadMovies(contentType: 'cinema');
  /// ```
  Future<void> loadMovies({
    String? contentType,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _selectedContentType = contentType;
    notifyListeners();

    try {
      final movies = await _movieRepository.getAllMovies(
        contentType: contentType,
      );
      _movies = movies;
      _error = null;
    } catch (e) {
      _error = 'Filmler yüklenirken hata: $e';
      print('Load movies error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Türe göre filmleri yükle
  /// 
  /// [genreId]: Tür ID
  /// [contentType]: İçerik türü filtresi (opsiyonel)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.loadMoviesByGenre(1); // Fantastik
  /// ```
  Future<void> loadMoviesByGenre(
    int genreId, {
    String? contentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final movies = await _movieRepository.getMoviesByGenre(
        genreId,
        contentType: contentType,
      );
      _movies = movies;
      _selectedGenre = _genres.firstWhere(
        (g) => g['id'] == genreId,
        orElse: () => {},
      );
      _error = null;
    } catch (e) {
      _error = 'Türe göre filmler yüklenirken hata: $e';
      print('Load by genre error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Film arama yap
  /// 
  /// [query]: Aranacak kelime
  /// [contentType]: İçerik türü filtresi (opsiyonel)
  /// 
  /// Arama sonuçları [searchResults]'ta tutulur
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.searchMovies('Matrix');
  /// final results = movieProvider.searchResults;
  /// ```
  Future<void> searchMovies(
    String query, {
    String? contentType,
  }) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _movieRepository.searchMovies(
        query,
        contentType: contentType,
      );
      _error = null;
    } catch (e) {
      _error = 'Arama sırasında hata: $e';
      _searchResults = [];
      print('Search error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Arama sonuçlarını temizle
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Film seç ve detaylarını yükle
  /// 
  /// [movie]: Seçilecek film
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
      // Eğer dizi ise sezonları yükle
      if (movie.isSeries) {
        _seasons = await _movieRepository.getSeasons(movie.id);
        if (_seasons.isNotEmpty) {
          _selectedSeason = _seasons[0];
          _episodes = await _movieRepository.getEpisodes(_seasons[0].id);
          if (_episodes.isNotEmpty) {
            _selectedEpisode = _episodes[0];
          }
        }
      }

      // Yorumları yükle
      await _loadComments(movie.id);

      _error = null;
    } catch (e) {
      _error = 'Film seçme hatası: $e';
      print('Select movie error: $e');
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
    _selectedSeason = season;
    _isLoading = true;
    notifyListeners();

    try {
      _episodes = await _movieRepository.getEpisodes(season.id);
      if (_episodes.isNotEmpty) {
        _selectedEpisode = _episodes[0];
      }
      _error = null;
    } catch (e) {
      _error = 'Sezon seçme hatası: $e';
      print('Select season error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bölüm seç (Dizi için oynatma)
  /// 
  /// [episode]: Seçilecek bölüm
  /// 
  /// Örnek:
  /// ```dart
  /// movieProvider.selectEpisode(episode);
  /// ```
  void selectEpisode(MovieEpisode episode) {
    _selectedEpisode = episode;
    notifyListeners();
  }

  /// Filmin yorumlarını yükle
  Future<void> _loadComments(int movieId) async {
    try {
      _comments = await _movieRepository.getComments(movieId);
      notifyListeners();
    } catch (e) {
      print('Load comments error: $e');
    }
  }

  /// Yorum ekle
  /// 
  /// [userId]: Yorum yapan kullanıcı ID
  /// [commentText]: Yorum metni
  /// [rating]: Puan (1-10)
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.addComment(
  ///   userId: 'user-id',
  ///   commentText: 'Harika bir film!',
  ///   rating: 9,
  /// );
  /// ```
  Future<bool> addComment({
    required String userId,
    required String commentText,
    int? rating,
  }) async {
    if (_selectedMovie == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _movieRepository.addComment(
        movieId: _selectedMovie!.id,
        userId: userId,
        commentText: commentText,
        rating: rating,
      );

      // Yorumları yeniden yükle
      await _loadComments(_selectedMovie!.id);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Yorum ekleme hatası: $e';
      print('Add comment error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
  /// await movieProvider.addCommentReaction(
  ///   commentId: 1,
  ///   userId: 'user-id',
  ///   reactionType: 'like',
  /// );
  /// ```
  Future<bool> addCommentReaction({
    required int commentId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _movieRepository.addCommentReaction(
        commentId: commentId,
        userId: userId,
        reactionType: reactionType,
      );
      return true;
    } catch (e) {
      _error = 'Reaksiyon ekleme hatası: $e';
      print('Add reaction error: $e');
      return false;
    }
  }

  /// Film Rapor Et
  /// 
  /// [description]: Sorun açıklaması
  /// [userId]: Raporlayan kullanıcı ID
  /// 
  /// Örnek:
  /// ```dart
  /// await movieProvider.reportMovie(
  ///   description: 'Bozuk link',
  ///   userId: 'user-id',
  /// );
  /// ```
  Future<bool> reportMovie({
    required String description,
    required String userId,
  }) async {
    if (_selectedMovie == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _movieRepository.reportMovie(
        movieId: _selectedMovie!.id,
        description: description,
        userId: userId,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = 'Rapor etme hatası: $e';
      print('Report error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Daha fazla film yükle (pagination)
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
      final moreMovies = await _movieRepository.getAllMovies(
        contentType: _selectedContentType,
        limit: 10,
        offset: _currentPage * 10,
      );
      _movies.addAll(moreMovies);
      _error = null;
    } catch (e) {
      _error = 'Daha fazla film yüklenirken hata: $e';
      _currentPage--; // Hata durumunda sayfayı geri al
      print('Load more error: $e');
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
